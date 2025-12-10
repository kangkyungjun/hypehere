"""
Custom template tags for legal document management.
Provides filters for nested dictionary access in templates.
"""
from django import template

register = template.Library()

@register.filter
def get_item(dictionary, key):
    """
    Template filter to access dictionary items by key.

    Usage in template:
        {{ documents|get_item:doc_type|get_item:lang_code }}

    Args:
        dictionary: Dictionary or dict-like object
        key: Key to access in dictionary

    Returns:
        Value at dictionary[key] or None if key doesn't exist
    """
    if dictionary is None:
        return None
    return dictionary.get(key)
