"""
Name Resolution Service Module

This module handles fuzzy name matching and resolution for assignees and controllers
in task creation, ensuring that user inputs are properly validated against the database.
"""

import logging
from typing import List, Tuple, Optional, Dict, Any
from .database_service import DatabaseService

logger = logging.getLogger(__name__)


class NameResolutionService:
    """
    Service for resolving and validating user names using fuzzy matching.
    """
    
    @staticmethod
    def resolve_assignees(assignees_input: str) -> Tuple[bool, Optional[str], List[str]]:
        """
        Resolve assignee names using fuzzy matching against QCheck_Groups table.
        
        Args:
            assignees_input: Comma-separated list of assignee names
            
        Returns:
            Tuple of (is_valid, resolved_assignees, clarification_needed)
            - is_valid: True if all names were resolved successfully
            - resolved_assignees: Comma-separated resolved names, or None if failed
            - clarification_needed: List of names that need clarification
        """
        if not assignees_input or assignees_input.strip() == "":
            return False, None, []
        
        # Split by comma and clean up
        assignee_names = [name.strip() for name in assignees_input.split(',') if name.strip()]
        
        resolved_names = []
        clarification_needed = []
        
        for name in assignee_names:
            # Use group validation instead of user validation for assignees
            is_valid, resolved_name, similar_names = DatabaseService.validate_group_exists(name)
            
            if is_valid:
                resolved_names.append(resolved_name)
            elif similar_names:
                # Multiple matches found - need clarification
                clarification_needed.append({
                    'input': name,
                    'options': similar_names
                })
            else:
                # No matches found
                logger.warning(f"No matches found for assignee group: {name}")
                return False, None, []
        
        if clarification_needed:
            # Store the original assignee list for later restoration
            clarification_needed_with_original = clarification_needed.copy()
            for item in clarification_needed_with_original:
                item['_original_assignees'] = assignees_input
            return False, None, clarification_needed_with_original
        
        resolved_assignees = ','.join(resolved_names)
        logger.info(f"Successfully resolved assignees: {assignees_input} -> {resolved_assignees}")
        return True, resolved_assignees, []
    
    @staticmethod
    def resolve_controllers(controllers_input: str) -> Tuple[bool, Optional[str], List[str]]:
        """
        Resolve controller names using fuzzy matching.
        
        Args:
            controllers_input: Comma-separated list of controller names
            
        Returns:
            Tuple of (is_valid, resolved_controllers, clarification_needed)
            - is_valid: True if all names were resolved successfully
            - resolved_controllers: Comma-separated resolved names, or None if failed
            - clarification_needed: List of names that need clarification
        """
        if not controllers_input or controllers_input.strip() == "":
            return False, None, []
        
        # Split by comma and clean up
        controller_names = [name.strip() for name in controllers_input.split(',') if name.strip()]
        
        resolved_names = []
        clarification_needed = []
        
        for name in controller_names:
            is_valid, resolved_name, similar_names = DatabaseService.validate_and_resolve_user_name(name, "controller")
            
            if is_valid:
                resolved_names.append(resolved_name)
            elif similar_names:
                # Multiple matches found - need clarification
                clarification_needed.append({
                    'input': name,
                    'options': similar_names
                })
            else:
                # No matches found
                logger.warning(f"No matches found for controller: {name}")
                return False, None, []
        
        if clarification_needed:
            return False, None, clarification_needed
        
        resolved_controllers = ','.join(resolved_names)
        logger.info(f"Successfully resolved controllers: {controllers_input} -> {resolved_controllers}")
        return True, resolved_controllers, []
    
    @staticmethod
    def format_clarification_message(clarification_needed: List[Dict[str, Any]], role: str) -> str:
        """
        Format a user-friendly message asking for clarification on ambiguous names.
        
        Args:
            clarification_needed: List of names that need clarification
            role: The role being clarified ("assignee" or "controller")
            
        Returns:
            Formatted clarification message
        """
        if not clarification_needed:
            return ""
        
        messages = []
        for item in clarification_needed:
            input_name = item['input']
            options = item['options']
            
            options_text = " or ".join([f"'{opt}'" for opt in options])
            message = f"Are you referring to {options_text} when you mentioned '{input_name}'?"
            messages.append(message)
        
        role_text = "assignee" if role == "assignee" else "controller"
        return f"I found multiple people with similar names for the {role_text}. " + " ".join(messages) + " Please clarify which one you meant."
    
    @staticmethod
    def validate_task_parameters(params: Dict[str, Any]) -> Tuple[bool, Optional[str], Dict[str, Any]]:
        """
        Validate and resolve all user names in task parameters.
        
        Args:
            params: Task parameters dictionary
            
        Returns:
            Tuple of (is_valid, error_message, updated_params)
            - is_valid: True if all names were resolved successfully
            - error_message: Error message if validation failed, or None
            - updated_params: Updated parameters with resolved names, or original params if failed
        """
        updated_params = params.copy()
        
        # Resolve assignees
        assignees = params.get('Assignees', '')
        if assignees:
            is_valid, resolved_assignees, clarification_needed = NameResolutionService.resolve_assignees(assignees)
            
            if not is_valid:
                if clarification_needed:
                    error_message = NameResolutionService.format_clarification_message(clarification_needed, "assignee")
                    return False, error_message, params
                else:
                    return False, f"Could not find any groups matching the assignee names: {assignees}", params
            
            updated_params['Assignees'] = resolved_assignees
        
        # Resolve controllers
        controllers = params.get('Controllers', '')
        if controllers:
            is_valid, resolved_controllers, clarification_needed = NameResolutionService.resolve_controllers(controllers)
            
            if not is_valid:
                if clarification_needed:
                    error_message = NameResolutionService.format_clarification_message(clarification_needed, "controller")
                    return False, error_message, params
                else:
                    return False, f"Could not find any users matching the controller names: {controllers}", params
            
            updated_params['Controllers'] = resolved_controllers
        
        logger.info("Successfully validated and resolved all user names in task parameters")
        return True, None, updated_params
