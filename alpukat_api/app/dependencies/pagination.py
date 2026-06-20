from fastapi import Query


class PaginationParams:
    def __init__(
        self,
        page: int = Query(default=1, ge=1, description="Halaman ke-"),
        per_page: int = Query(default=10, ge=1, le=100, description="Jumlah item per halaman"),
    ):
        self.page = page
        self.per_page = per_page
        self.offset = (page - 1) * per_page
