import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def handler(*args, **kwargs):
    logger.info("Yo")
    return {
        "isBase64Encoded": True,
        "statusCode": 200,
        # "headers": { "headerName": "headerValue", ... },
        "body": "ok",
    }
