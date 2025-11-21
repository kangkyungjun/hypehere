"""
Anonymous Chat Matching System
Implements FIFO queue-based matching with gender and country filters
"""
from threading import Lock
from typing import Optional, Dict, List
from datetime import datetime
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class AnonymousMatchingQueue:
    """
    Thread-safe FIFO matching queue for anonymous 1:1 chat
    Stores waiting users and matches them based on preferences
    """

    def __init__(self):
        self._queue: List[Dict] = []
        self._lock = Lock()

    def add_to_queue(self, user_id: int, preferences: Dict) -> bool:
        """
        Add user to matching queue

        Args:
            user_id: User ID to add to queue
            preferences: Dict with 'preferred_gender', 'preferred_country', and 'chat_mode'

        Returns:
            bool: True if added successfully, False if already in queue
        """
        with self._lock:
            # Check if user already in queue
            if any(item['user_id'] == user_id for item in self._queue):
                return False

            # Add to queue with timestamp
            self._queue.append({
                'user_id': user_id,
                'preferred_gender': preferences.get('preferred_gender', 'any'),
                'preferred_country': preferences.get('preferred_country', ''),
                'chat_mode': preferences.get('chat_mode', 'text'),
                'joined_at': datetime.now()
            })
            return True

    def find_match(self, user_id: int, preferences: Dict) -> Optional[int]:
        """
        Find matching partner based on preferences (FIFO)

        Args:
            user_id: Current user's ID
            preferences: Dict with 'preferred_gender', 'preferred_country', and 'chat_mode'

        Returns:
            Optional[int]: Matched user ID or None if no match found
        """
        with self._lock:
            try:
                # Get current user data
                user = User.objects.get(id=user_id)
                user_gender = user.gender if user.gender else 'prefer_not_to_say'
                user_country = user.country if user.country else ''

                preferred_gender = preferences.get('preferred_gender', 'any')
                preferred_country = preferences.get('preferred_country', '')
                chat_mode = preferences.get('chat_mode', 'text')

                # Find first compatible match in queue
                for i, waiting_user in enumerate(self._queue):
                    # Skip self
                    if waiting_user['user_id'] == user_id:
                        continue

                    try:
                        partner = User.objects.get(id=waiting_user['user_id'])
                        partner_gender = partner.gender if partner.gender else 'prefer_not_to_say'
                        partner_country = partner.country if partner.country else ''
                    except User.DoesNotExist:
                        # Remove invalid user from queue
                        self._queue.pop(i)
                        continue

                    # Check if current user meets waiting user's preferences
                    meets_partner_gender = (
                        waiting_user['preferred_gender'] == 'any' or
                        waiting_user['preferred_gender'] == user_gender
                    )
                    meets_partner_country = (
                        not waiting_user['preferred_country'] or
                        waiting_user['preferred_country'] == user_country
                    )

                    # Check if waiting user meets current user's preferences
                    meets_user_gender = (
                        preferred_gender == 'any' or
                        preferred_gender == partner_gender
                    )
                    meets_user_country = (
                        not preferred_country or
                        preferred_country == partner_country
                    )

                    # Check if chat modes match (must be exact match)
                    same_chat_mode = waiting_user.get('chat_mode', 'text') == chat_mode

                    # Both users must meet each other's preferences AND have same chat mode
                    if (meets_partner_gender and meets_partner_country and
                        meets_user_gender and meets_user_country and same_chat_mode):
                        # Match found - remove from queue and return
                        matched_user_id = waiting_user['user_id']
                        self._queue.pop(i)
                        return matched_user_id

                # No match found
                return None

            except User.DoesNotExist:
                return None

    def remove_from_queue(self, user_id: int) -> bool:
        """
        Remove user from matching queue

        Args:
            user_id: User ID to remove

        Returns:
            bool: True if removed, False if not in queue
        """
        with self._lock:
            initial_length = len(self._queue)
            self._queue = [item for item in self._queue if item['user_id'] != user_id]
            return len(self._queue) < initial_length

    def get_queue_position(self, user_id: int) -> Optional[int]:
        """
        Get user's position in queue (1-indexed)

        Args:
            user_id: User ID

        Returns:
            Optional[int]: Queue position or None if not in queue
        """
        with self._lock:
            for i, item in enumerate(self._queue):
                if item['user_id'] == user_id:
                    return i + 1
            return None

    def get_queue_size(self) -> int:
        """Get current queue size"""
        with self._lock:
            return len(self._queue)

    def clear_queue(self) -> int:
        """
        Clear entire queue (admin/debug only)

        Returns:
            int: Number of users removed
        """
        with self._lock:
            count = len(self._queue)
            self._queue.clear()
            return count


# Global singleton instance
matching_queue = AnonymousMatchingQueue()


def create_anonymous_conversation(user1_id: int, user2_id: int):
    """
    Create anonymous conversation between two matched users

    Args:
        user1_id: First user ID
        user2_id: Second user ID

    Returns:
        Conversation: Created anonymous conversation
    """
    from .models import Conversation, ConversationParticipant

    # Generate unique anonymous room ID
    room_id = str(uuid.uuid4())[:8]

    # Create anonymous conversation
    conversation = Conversation.objects.create(
        is_anonymous=True,
        is_ephemeral=True,
        anonymous_room_id=room_id
    )

    # Add both participants
    user1 = User.objects.get(id=user1_id)
    user2 = User.objects.get(id=user2_id)

    ConversationParticipant.objects.create(
        user=user1,
        conversation=conversation,
        is_active=True
    )

    ConversationParticipant.objects.create(
        user=user2,
        conversation=conversation,
        is_active=True
    )

    return conversation
