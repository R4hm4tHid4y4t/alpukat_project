import time
import numpy as np
from io import BytesIO
from PIL import Image
from typing import Optional


class TFLiteInferenceService:
    _varietas_interpreter = None
    _kematangan_interpreter = None
    _initialized: bool = False

    # Urutan class_names sesuai urutan abjad folder saat training
    VARIETAS_CLASSES = ["Aligator", "Miki"]
    KEMATANGAN_CLASSES = ["Matang", "Mentah", "Setengah_Matang", "Terlalu_Matang"]
    KEMATANGAN_DISPLAY = {
        "Matang": "Matang",
        "Mentah": "Mentah",
        "Setengah_Matang": "Setengah Matang",
        "Terlalu_Matang": "Terlalu Matang",
    }

    @classmethod
    def initialize(cls, settings) -> None:
        try:
            import tflite_runtime.interpreter as tflite
        except ImportError:
            import tensorflow as tf
            tflite = tf.lite

        # Load model varietas
        cls._varietas_interpreter = tflite.Interpreter(
            model_path=settings.model_varietas_path
        )
        cls._varietas_interpreter.allocate_tensors()

        # Load model kematangan
        cls._kematangan_interpreter = tflite.Interpreter(
            model_path=settings.model_kematangan_path
        )
        cls._kematangan_interpreter.allocate_tensors()

        cls._initialized = True

    @classmethod
    def _check_initialized(cls):
        if not cls._initialized:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=503,
                detail="Model belum diinisialisasi. Hubungi administrator.",
            )

    @staticmethod
    def preprocess_image(image_bytes: bytes) -> np.ndarray:
        img = Image.open(BytesIO(image_bytes)).convert("RGB")
        img = img.resize((224, 224), Image.LANCZOS)
        img_array = np.array(img, dtype=np.float32)
        img_array = img_array / 127.5 - 1.0  # normalisasi MobileNetV2
        return np.expand_dims(img_array, axis=0)

    @classmethod
    async def predict_varietas(cls, image_bytes: bytes) -> dict:
        cls._check_initialized()
        start = time.time()

        img_array = cls.preprocess_image(image_bytes)
        interp = cls._varietas_interpreter

        input_idx = interp.get_input_details()[0]["index"]
        output_idx = interp.get_output_details()[0]["index"]

        interp.set_tensor(input_idx, img_array)
        interp.invoke()

        output = interp.get_tensor(output_idx)[0]
        pred_idx = int(np.argmax(output))
        confidence = float(output[pred_idx]) * 100
        inference_ms = (time.time() - start) * 1000

        return {
            "class_name": cls.VARIETAS_CLASSES[pred_idx],
            "confidence": round(confidence, 2),
            "all_probabilities": {
                name: round(float(prob) * 100, 2)
                for name, prob in zip(cls.VARIETAS_CLASSES, output)
            },
            "inference_time_ms": round(inference_ms, 2),
        }

    @classmethod
    async def predict_kematangan(cls, image_bytes: bytes) -> dict:
        cls._check_initialized()
        start = time.time()

        img_array = cls.preprocess_image(image_bytes)
        interp = cls._kematangan_interpreter

        input_idx = interp.get_input_details()[0]["index"]
        output_idx = interp.get_output_details()[0]["index"]

        interp.set_tensor(input_idx, img_array)
        interp.invoke()

        output = interp.get_tensor(output_idx)[0]
        pred_idx = int(np.argmax(output))
        class_name = cls.KEMATANGAN_CLASSES[pred_idx]
        confidence = float(output[pred_idx]) * 100
        inference_ms = (time.time() - start) * 1000

        return {
            "class_name": class_name,
            "display_name": cls.KEMATANGAN_DISPLAY[class_name],
            "confidence": round(confidence, 2),
            "all_probabilities": {
                cls.KEMATANGAN_DISPLAY[name]: round(float(prob) * 100, 2)
                for name, prob in zip(cls.KEMATANGAN_CLASSES, output)
            },
            "inference_time_ms": round(inference_ms, 2),
        }

    @classmethod
    def reload(cls, varietas_path: str, kematangan_path: str, settings) -> None:
        cls._initialized = False
        cls._varietas_interpreter = None
        cls._kematangan_interpreter = None

        class TempSettings:
            model_varietas_path = varietas_path
            model_kematangan_path = kematangan_path

        cls.initialize(TempSettings())
