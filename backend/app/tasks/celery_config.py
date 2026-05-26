from celery import Celery
from celery.schedules import crontab

from app.core.config import get_settings

settings = get_settings()

celery_app = Celery(
    "digitalpmo",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=[
        "app.tasks.reminder_tasks",
        "app.tasks.risk_score_tasks",
        "app.tasks.report_tasks",
    ],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Jakarta",
    enable_utc=True,
    task_track_started=True,
    worker_prefetch_multiplier=1,
    task_acks_late=True,
)

celery_app.conf.beat_schedule = {
    # Every minute: check if any patient's schedule time is ±1 min from now
    "daily-medication-reminders": {
        "task": "app.tasks.reminder_tasks.send_daily_medication_reminders",
        "schedule": 60.0,  # every 60 seconds
    },
    # Every day at 08:00 WIB: send H-3/H-1/H-0 control reminders
    "control-reminders": {
        "task": "app.tasks.reminder_tasks.send_control_reminders",
        "schedule": crontab(hour=8, minute=0),
    },
    # Every Sunday at 00:00 WIB: calculate dropout risk scores
    "weekly-risk-scores": {
        "task": "app.tasks.risk_score_tasks.calculate_weekly_risk_scores",
        "schedule": crontab(day_of_week="sun", hour=0, minute=0),
    },
    # 1st of every month at 01:00 WIB: generate monthly reports for previous month
    "monthly-reports": {
        "task": "app.tasks.report_tasks.generate_monthly_reports",
        "schedule": crontab(day_of_month=1, hour=1, minute=0),
    },
}
