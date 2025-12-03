"""
Django management command to delete old report evidence.

Usage:
    python manage.py delete_old_evidence [--days=30] [--dry-run]

This command deletes report evidence (message_snapshot and video_frame) that is older than
the specified number of days to comply with privacy regulations and data retention policies.
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db.models import Q
from datetime import timedelta
import os

from chat.models import Report


class Command(BaseCommand):
    help = 'Delete old report evidence to comply with privacy regulations'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=30,
            help='Delete evidence older than this many days (default: 30)'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting'
        )

    def handle(self, *args, **options):
        days = options['days']
        dry_run = options['dry_run']
        
        cutoff_date = timezone.now() - timedelta(days=days)
        
        self.stdout.write(self.style.WARNING(
            f"\n{'=' * 80}\n"
            f"Report Evidence Cleanup\n"
            f"{'=' * 80}\n"
        ))
        
        if dry_run:
            self.stdout.write(self.style.NOTICE("[DRY RUN MODE] No data will be deleted\n"))
        
        self.stdout.write(f"Cutoff date: {cutoff_date.strftime('%Y-%m-%d %H:%M:%S')}\n")
        self.stdout.write(f"Deleting evidence older than {days} days\n\n")
        
        # Find reports with evidence older than cutoff date
        reports_with_evidence = Report.objects.filter(
            created_at__lt=cutoff_date
        ).filter(
            Q(message_snapshot__isnull=False) | Q(video_frame__isnull=False, video_frame__exact='')
        )
        
        total_reports = reports_with_evidence.count()
        
        if total_reports == 0:
            self.stdout.write(self.style.SUCCESS(
                "✓ No old evidence found. All evidence is within retention period.\n"
            ))
            return
        
        self.stdout.write(f"Found {total_reports} reports with old evidence:\n")
        
        # Count evidence types
        message_snapshot_count = reports_with_evidence.filter(
            message_snapshot__isnull=False
        ).count()
        video_frame_count = reports_with_evidence.filter(
            ~Q(video_frame='')
        ).filter(video_frame__isnull=False).count()
        
        self.stdout.write(f"  - Message snapshots: {message_snapshot_count}\n")
        self.stdout.write(f"  - Video frames: {video_frame_count}\n\n")
        
        if dry_run:
            self.stdout.write(self.style.WARNING(
                "Would delete evidence from these reports (DRY RUN):\n"
            ))
            for report in reports_with_evidence[:10]:  # Show first 10
                self.stdout.write(
                    f"  Report #{report.id}: "
                    f"created {report.created_at.strftime('%Y-%m-%d')}, "
                    f"status={report.status}\n"
                )
            if total_reports > 10:
                self.stdout.write(f"  ... and {total_reports - 10} more\n")
            
            self.stdout.write(self.style.SUCCESS(
                f"\n✓ DRY RUN complete. Would delete evidence from {total_reports} reports.\n"
            ))
            return
        
        # Actually delete evidence
        self.stdout.write("Deleting evidence...\n")
        
        deleted_files = 0
        updated_reports = 0
        
        for report in reports_with_evidence:
            # Delete video frame file if exists
            if report.video_frame:
                try:
                    file_path = report.video_frame.path
                    if os.path.exists(file_path):
                        os.remove(file_path)
                        deleted_files += 1
                        self.stdout.write(f"  Deleted file: {file_path}\n")
                except Exception as e:
                    self.stdout.write(self.style.WARNING(
                        f"  Warning: Could not delete file {report.video_frame.name}: {e}\n"
                    ))
                
                report.video_frame = None
            
            # Clear message snapshot
            if report.message_snapshot:
                report.message_snapshot = None
            
            report.save()
            updated_reports += 1
        
        self.stdout.write(self.style.SUCCESS(
            f"\n{'=' * 80}\n"
            f"✓ Cleanup complete!\n"
            f"{'=' * 80}\n"
            f"  Updated reports: {updated_reports}\n"
            f"  Deleted files: {deleted_files}\n"
            f"  Total evidence cleared: {message_snapshot_count} message snapshots, {video_frame_count} video frames\n"
        ))
