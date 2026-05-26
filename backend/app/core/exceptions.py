from fastapi import HTTPException, status


class AppException(HTTPException):
    def __init__(self, status_code: int, detail: str):
        super().__init__(status_code=status_code, detail=detail)


class AuthException(AppException):
    def __init__(self, detail: str = "Autentikasi gagal. Silakan login kembali."):
        super().__init__(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)


class ForbiddenException(AppException):
    def __init__(self, detail: str = "Anda tidak memiliki izin untuk mengakses resource ini."):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


class NotFoundException(AppException):
    def __init__(self, detail: str = "Resource yang diminta tidak ditemukan."):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


class ConflictException(AppException):
    def __init__(self, detail: str = "Resource sudah ada atau terjadi konflik data."):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail)


class ValidationException(AppException):
    def __init__(self, detail: str = "Data yang diberikan tidak valid."):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=detail
        )


class ServiceException(AppException):
    def __init__(self, detail: str = "Terjadi kesalahan pada server. Silakan coba lagi."):
        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=detail
        )
