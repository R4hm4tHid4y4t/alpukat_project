from fastapi.responses import JSONResponse
from typing import Any, Optional


def success_response(
    data: Any = None,
    message: str = "Berhasil",
    status_code: int = 200,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "success": True,
            "message": message,
            "data": data,
            "errors": None,
        },
    )


def error_response(
    message: str = "Terjadi kesalahan",
    errors: Optional[Any] = None,
    status_code: int = 400,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "message": message,
            "data": None,
            "errors": errors,
        },
    )


def paginated_response(
    items: list,
    total: int,
    page: int,
    per_page: int,
    message: str = "Berhasil",
) -> JSONResponse:
    last_page = (total + per_page - 1) // per_page
    return JSONResponse(
        status_code=200,
        content={
            "success": True,
            "message": message,
            "data": {
                "items": items,
                "meta": {
                    "total": total,
                    "page": page,
                    "per_page": per_page,
                    "last_page": last_page,
                },
            },
            "errors": None,
        },
    )
