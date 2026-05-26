import logging

logger = logging.getLogger(__name__)

_scheduler = None


def get_scheduler():
    global _scheduler
    if _scheduler is None:
        try:
            from apscheduler.schedulers.background import BackgroundScheduler
            from apscheduler.triggers.cron import CronTrigger
            from apscheduler.triggers.interval import IntervalTrigger

            _scheduler = BackgroundScheduler(timezone="Asia/Jakarta")

            # Every minute: medication reminders (±1 min of scheduled time)
            _scheduler.add_job(
                _dispatch_daily_medication_reminders,
                trigger=IntervalTrigger(minutes=1),
                id="daily_medication_reminders",
                replace_existing=True,
            )

            # Every day at 08:00: control reminders (H-3/H-1/H-0)
            _scheduler.add_job(
                _dispatch_control_reminders,
                trigger=CronTrigger(hour=8, minute=0, timezone="Asia/Jakarta"),
                id="control_reminders",
                replace_existing=True,
            )

            # Every Sunday at 00:00: weekly risk score calculation
            _scheduler.add_job(
                _dispatch_weekly_risk_scores,
                trigger=CronTrigger(
                    day_of_week="sun", hour=0, minute=0, timezone="Asia/Jakarta"
                ),
                id="weekly_risk_scores",
                replace_existing=True,
            )

            # 1st of every month at 01:00: monthly report generation
            _scheduler.add_job(
                _dispatch_monthly_reports,
                trigger=CronTrigger(day=1, hour=1, minute=0, timezone="Asia/Jakarta"),
                id="monthly_reports",
                replace_existing=True,
            )

        except ImportError:
            logger.warning(
                "APScheduler not installed. Falling back to Celery beat for scheduling."
            )
            _scheduler = None

    return _scheduler


def _dispatch_daily_medication_reminders():
    try:
        from app.tasks.reminder_tasks import send_daily_medication_reminders

        send_daily_medication_reminders.delay()
    except Exception as e:
        logger.error("Failed to dispatch daily medication reminders: %s", e)


def _dispatch_control_reminders():
    try:
        from app.tasks.reminder_tasks import send_control_reminders

        send_control_reminders.delay()
    except Exception as e:
        logger.error("Failed to dispatch control reminders: %s", e)


def _dispatch_weekly_risk_scores():
    try:
        from app.tasks.risk_score_tasks import calculate_weekly_risk_scores

        calculate_weekly_risk_scores.delay()
    except Exception as e:
        logger.error("Failed to dispatch weekly risk scores: %s", e)


def _dispatch_monthly_reports():
    try:
        from app.tasks.report_tasks import generate_monthly_reports

        generate_monthly_reports.delay()
    except Exception as e:
        logger.error("Failed to dispatch monthly reports: %s", e)


def start_scheduler():
    scheduler = get_scheduler()
    if scheduler is None:
        logger.info("APScheduler not available; Celery beat handles scheduling.")
        return
    if not scheduler.running:
        scheduler.start()
        logger.info("APScheduler started with %d jobs.", len(scheduler.get_jobs()))


def stop_scheduler():
    scheduler = get_scheduler()
    if scheduler and scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler stopped.")
