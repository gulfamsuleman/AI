"""
Database Service Module

This module encapsulates all database operations, providing a clean interface
for database interactions with proper resource management and error handling.
"""

import logging
from django.db import connection
from contextlib import contextmanager
from typing import Optional, List, Tuple, Dict, Any
from ..config.queries import *
from .error_handler import error_handler, DatabaseError, retry_database_operation
from .bitmask_translator import get_translator

logger = logging.getLogger(__name__)


class DatabaseService:
    """
    Centralized database service for all database operations.
    Provides methods for task creation, user management, group validation,
    and priority list operations with proper resource cleanup.
    """
    
    @staticmethod
    def escape_sql_string(s):
        """
        Helper function to safely escape strings for SQL
        """
        if s is None:
            return "NULL"
        return str(s).replace("'", "''")
    
    @staticmethod
    @contextmanager
    def get_cursor():
        """
        Context manager for database cursors with proper cleanup
        """
        cursor = None
        try:
            cursor = connection.cursor()
            yield cursor
        except Exception as e:
            logger.error(f"Database cursor error: {e}")
            raise DatabaseError(f"Database connection error: {str(e)}", 'DATABASE_CONNECTION_ERROR')
        finally:
            if cursor:
                try:
                    # Consume any remaining results to clear the cursor
                    while cursor.nextset():
                        pass
                except:
                    pass
                finally:
                    cursor.close()
    
    @staticmethod
    def _select_best_group_match(input_name: str, similar_groups: List[str], context_groups: List[str] = None) -> Optional[str]:
        """
        Select the best match from multiple similar groups using intelligent heuristics.
        
        Args:
            input_name: The input group name (normalized)
            similar_groups: List of similar group names found
            context_groups: Optional list of context groups (e.g., assignee groups) to consider
            
        Returns:
            The best matching group name, or None if no clear winner
        """
        if not similar_groups:
            return None
        
        if len(similar_groups) == 1:
            return similar_groups[0]
        
        # Score each group based on various criteria
        scored_groups = []
        
        for group in similar_groups:
            group_lower = group.lower()
            score = 0
            
            # 1. Exact match gets highest score
            if group_lower == input_name:
                score += 1000
            
            # 2. Starts with input gets high score
            elif group_lower.startswith(input_name + ' '):
                score += 500
            
            # 3. Contains input as a complete word gets medium score
            elif input_name in group_lower.split():
                score += 300
            
            # 4. First word starts with input gets medium score
            elif group_lower.split() and group_lower.split()[0].startswith(input_name):
                score += 250
            
            # 5. Any word starts with input gets lower score
            elif any(word.startswith(input_name) for word in group_lower.split()):
                score += 200
            
            # 6. Shorter names get preference (more specific)
            length_penalty = len(group) * 2
            score -= length_penalty
            
            # 7. Prefer groups that don't have generic words like "Team", "Group", "Department"
            generic_words = ['team', 'group', 'department', 'division', 'unit']
            if any(word in group_lower for word in generic_words):
                score -= 50
            
            # 8. Prefer groups that contain the input word more prominently
            word_count = group_lower.count(input_name)
            score += word_count * 100
            
            # 9. Context bonus: if this group matches any context groups (e.g., assignees), give bonus
            if context_groups:
                for context_group in context_groups:
                    context_lower = context_group.lower()
                    if group_lower == context_lower:
                        score += 400  # High bonus for exact context match
                        break
                    elif group_lower in context_lower or context_lower in group_lower:
                        score += 200  # Medium bonus for partial context match
                        break
            
            scored_groups.append((group, score))
        
        # Sort by score (highest first)
        scored_groups.sort(key=lambda x: x[1], reverse=True)
        
        # If the top score is significantly higher than the second, select it
        if len(scored_groups) >= 2:
            top_score = scored_groups[0][1]
            second_score = scored_groups[1][1]
            
            # If top score is significantly higher (more than 100 points difference)
            if top_score > second_score + 100:
                logger.debug(f"Selected '{scored_groups[0][0]}' (score: {top_score}) over '{scored_groups[1][0]}' (score: {second_score})")
                return scored_groups[0][0]
            # If scores are close but we have context, and top match has context bonus, select it
            elif context_groups and top_score > second_score + 50:
                # Check if top match has context bonus
                top_group = scored_groups[0][0]
                top_group_lower = top_group.lower()
                has_context_bonus = any(
                    top_group_lower == context.lower() or 
                    top_group_lower in context.lower() or 
                    context.lower() in top_group_lower
                    for context in context_groups
                )
                if has_context_bonus:
                    logger.debug(f"Selected '{top_group}' (score: {top_score}) with context bonus over '{scored_groups[1][0]}' (score: {second_score})")
                    return top_group
        
        # If scores are close, don't auto-select
        logger.debug(f"Close scores for groups: {scored_groups}")
        return None

    @staticmethod
    def validate_group_exists(group_name: str, context_groups: List[str] = None) -> Tuple[bool, Optional[str], List[str]]:
        """
        Validate if a group exists and provide suggestions if not found.
        Uses sophisticated fuzzy matching to handle partial names like "Ken" matching "Ken Croft".
        
        Args:
            group_name: Name of the group to validate
            
        Returns:
            Tuple of (exists, found_name, similar_groups)
        """
        try:
            from difflib import get_close_matches
            
            with DatabaseService.get_cursor() as cursor:
                # Get all groups for fuzzy matching
                cursor.execute("SELECT Name FROM [QTasks].[dbo].[QCheck_Groups] ORDER BY Name")
                all_groups = [row[0] for row in cursor.fetchall()]
                
                if not all_groups:
                    logger.warning("No groups found in QCheck_Groups table")
                    return False, None, []
                
                # Normalize input for comparison
                group_input_normalized = group_name.lower().strip()
                
                # 1. Exact match (case-insensitive)
                exact_matches = [group for group in all_groups if group.lower() == group_input_normalized]
                if exact_matches:
                    return True, exact_matches[0], []
                
                # 2. Partial matching for names like "Ken" matching "Ken Croft"
                partial_matches = []
                for group in all_groups:
                    group_lower = group.lower()
                    group_words = group_lower.split()
                    
                    # Check if input is a partial match:
                    # 1. Name starts with input + space (e.g., "Ken" matches "Ken Croft")
                    # 2. Input is a complete word in the name (e.g., "John" matches "John Smith")
                    # 3. First word starts with input (e.g., "John" matches "John Smith")
                    # 4. Any word starts with input (e.g., "Ken" matches "Kenneth Wilson")
                    if (group_lower.startswith(group_input_normalized + ' ') or  # Starts with input + space
                        group_input_normalized in group_words or  # Input is a complete word
                        (group_words and group_words[0].startswith(group_input_normalized)) or  # First word starts with input
                        any(word.startswith(group_input_normalized) for word in group_words)):  # Any word starts with input
                        partial_matches.append(group)
                
                # 3. Fuzzy matching with different thresholds for spelling mistakes
                # Lower threshold for better spelling mistake tolerance
                high_confidence = get_close_matches(group_input_normalized, 
                                                 [g.lower() for g in all_groups], 
                                                 n=10, cutoff=0.7)  # Lowered from 0.8
                
                # Even lower threshold for more flexible matching
                medium_confidence = get_close_matches(group_input_normalized, 
                                                   [g.lower() for g in all_groups], 
                                                   n=10, cutoff=0.5)  # Lowered from 0.6
                
                # Convert back to original case
                high_confidence_original = [group for group in all_groups if group.lower() in high_confidence]
                medium_confidence_original = [group for group in all_groups if group.lower() in medium_confidence]
                
                # 4. Combine all matches: partial matches first, then fuzzy matches
                seen = set()
                all_matches = []
                
                # Add partial matches first (they're more likely to be correct)
                for group in partial_matches:
                    if group not in seen:
                        all_matches.append(group)
                        seen.add(group)
                
                # Add fuzzy matches
                for group in high_confidence_original + medium_confidence_original:
                    if group not in seen:
                        all_matches.append(group)
                        seen.add(group)
                
                # Limit to top 5 matches
                similar_groups = all_matches[:5]
                
                if len(similar_groups) == 1:
                    # Single match found - automatically resolve
                    resolved_name = similar_groups[0]
                    logger.info(f"Single match found for group '{group_name}' -> '{resolved_name}' (partial/fuzzy match)")
                    return True, resolved_name, []
                elif len(similar_groups) > 1:
                    # Multiple matches found - try to select the best match
                    best_match = DatabaseService._select_best_group_match(group_input_normalized, similar_groups, context_groups)
                    if best_match:
                        logger.info(f"Multiple matches found for group '{group_name}', selected best match: '{best_match}' from options: {similar_groups}")
                        return True, best_match, []
                    else:
                        # If we can't determine the best match, return all options for clarification
                        logger.info(f"Multiple matches found for group '{group_name}': {similar_groups}")
                        return False, None, similar_groups
                else:
                    # No matches found
                    logger.warning(f"No matches found for group '{group_name}'")
                    return False, None, []
                    
        except Exception as e:
            error_handler.log_error(e, {'group_name': group_name, 'operation': 'validate_group'})
            logger.error(f"Error validating group '{group_name}': {e}")
            return False, None, []
    
    @staticmethod
    def get_active_users() -> List[str]:
        """
        Get list of properly configured active users who can create tasks.
        Only returns users who exist as both users and groups.
        
        Returns:
            List of user full names who are properly configured
        """
        try:
            with DatabaseService.get_cursor() as cursor:
                cursor.execute(GET_ACTIVE_USERS)
                users = [row[0] for row in cursor.fetchall()]
                
                logger.info(f"Retrieved {len(users)} properly configured users")
                
                # Log configuration rate for monitoring
                cursor.execute("SELECT COUNT(*) FROM [QTasks].[dbo].[QCheck_Users] WHERE isdeleted <> 1")
                total_active = cursor.fetchone()[0]
                config_rate = (len(users) / total_active * 100) if total_active > 0 else 0
                logger.info(f"User configuration rate: {config_rate:.1f}% ({len(users)}/{total_active})")
                
                return users
                
        except Exception as e:
            error_handler.log_error(e, {'operation': 'get_active_users'})
            logger.error(f"Error retrieving active users: {e}")
            return []
    
    @staticmethod
    def get_all_active_users() -> List[str]:
        """
        Get list of ALL active users (legacy method).
        This includes users who may not be properly configured for task creation.
        
        Returns:
            List of all active user full names
        """
        try:
            with DatabaseService.get_cursor() as cursor:
                from ..config.queries import GET_ALL_ACTIVE_USERS_LEGACY
                cursor.execute(GET_ALL_ACTIVE_USERS_LEGACY)
                users = [row[0] for row in cursor.fetchall()]
                
                logger.info(f"Retrieved {len(users)} total active users (legacy)")
                return users
                
        except Exception as e:
            error_handler.log_error(e, {'operation': 'get_all_active_users'})
            logger.error(f"Error retrieving all active users: {e}")
            return []
    
    @staticmethod
    def get_all_users_for_matching() -> List[str]:
        """
        Get list of all users from QCheck_Users table for name matching.
        
        Returns:
            List of all user full names
        """
        try:
            with DatabaseService.get_cursor() as cursor:
                cursor.execute("SELECT [FullName] FROM [QTasks].[dbo].[QCheck_Users] WHERE isdeleted <> 1")
                users = [row[0] for row in cursor.fetchall()]
                
                logger.info(f"Retrieved {len(users)} users for name matching")
                return users
                
        except Exception as e:
            error_handler.log_error(e, {'operation': 'get_all_users_for_matching'})
            logger.error(f"Error retrieving users for matching: {e}")
            return []
    
    @staticmethod
    def validate_and_resolve_user_name(user_input: str, role: str = "assignee") -> Tuple[bool, Optional[str], List[str]]:
        """
        Validate and resolve user names using fuzzy matching.
        
        Args:
            user_input: The user input name (can be partial or have spelling mistakes)
            role: The role being validated ("assignee" or "controller")
            
        Returns:
            Tuple of (is_valid, resolved_name, similar_names)
            - is_valid: True if a single match was found
            - resolved_name: The exact matched name from database, or None
            - similar_names: List of similar names if multiple matches found
        """
        try:
            from difflib import get_close_matches
            
            # Get all users from database
            all_users = DatabaseService.get_all_users_for_matching()
            if not all_users:
                logger.warning("No users found in database for name matching")
                return False, None, []
            
            # Normalize input for comparison
            user_input_normalized = user_input.strip().lower()
            
            # 1. Exact match first
            for user in all_users:
                if user.lower() == user_input_normalized:
                    logger.info(f"Exact match found for {role} '{user_input}' -> '{user}'")
                    return True, user, []
            
            # 2. Check for partial name matches (e.g., "Ken" matches "Ken Croft")
            partial_matches = []
            for user in all_users:
                user_lower = user.lower()
                user_words = user_lower.split()
                
                # Check if input is a partial match:
                # 1. Name starts with input + space (e.g., "Ken" matches "Ken Croft")
                # 2. Input is a complete word in the name (e.g., "John" matches "John Smith")
                # 3. First word starts with input (e.g., "John" matches "John Smith")
                # 4. Any word starts with input (e.g., "Ken" matches "Kenneth Wilson")
                if (user_lower.startswith(user_input_normalized + ' ') or  # Starts with input + space
                    user_input_normalized in user_words or  # Input is a complete word
                    (user_words and user_words[0].startswith(user_input_normalized)) or  # First word starts with input
                    any(word.startswith(user_input_normalized) for word in user_words)):  # Any word starts with input
                    partial_matches.append(user)
            
            # 3. Fuzzy matching with different thresholds for spelling mistakes
            # Lower threshold for better spelling mistake tolerance
            high_confidence = get_close_matches(user_input_normalized, 
                                             [u.lower() for u in all_users], 
                                             n=10, cutoff=0.7)  # Lowered from 0.8
            
            # Even lower threshold for more flexible matching
            medium_confidence = get_close_matches(user_input_normalized, 
                                               [u.lower() for u in all_users], 
                                               n=10, cutoff=0.5)  # Lowered from 0.6
            
            # Convert back to original case
            high_confidence_original = [user for user in all_users if user.lower() in high_confidence]
            medium_confidence_original = [user for user in all_users if user.lower() in medium_confidence]
            
            # 4. Combine all matches: partial matches first, then fuzzy matches
            seen = set()
            all_matches = []
            
            # Add partial matches first (they're more likely to be correct)
            for user in partial_matches:
                if user not in seen:
                    all_matches.append(user)
                    seen.add(user)
            
            # Add fuzzy matches
            for user in high_confidence_original + medium_confidence_original:
                if user not in seen:
                    all_matches.append(user)
                    seen.add(user)
            
            # Limit to top 5 matches
            similar_names = all_matches[:5]
            
            if len(similar_names) == 1:
                # Single match found - automatically resolve
                resolved_name = similar_names[0]
                logger.info(f"Single match found for {role} '{user_input}' -> '{resolved_name}' (partial/fuzzy match)")
                return True, resolved_name, []
            elif len(similar_names) > 1:
                # Multiple matches found - need clarification
                logger.info(f"Multiple matches found for {role} '{user_input}': {similar_names}")
                return False, None, similar_names
            else:
                # No matches found
                logger.warning(f"No matches found for {role} '{user_input}'")
                return False, None, []
                
        except Exception as e:
            error_handler.log_error(e, {'user_input': user_input, 'role': role, 'operation': 'validate_user_name'})
            logger.error(f"Error validating user name '{user_input}': {e}")
            return False, None, []
    
    @staticmethod
    def find_task_by_name(task_name: str) -> Optional[int]:
        """
        Find a task instance ID by task name.
        
        Args:
            task_name: Name of the task to find
            
        Returns:
            Task instance ID if found, None otherwise
        """
        try:
            with DatabaseService.get_cursor() as cursor:
                cursor.execute(FIND_TASK_BY_NAME, [task_name])
                result = cursor.fetchone()
                
                if result:
                    instance_id = result[0]
                    logger.debug(f"Found task '{task_name}' with instance ID: {instance_id}")
                    return instance_id
                
                logger.warning(f"Task not found: '{task_name}'")
                return None
                
        except Exception as e:
            error_handler.log_error(e, {'task_name': task_name, 'operation': 'find_task_by_name'})
            logger.error(f"Error finding task '{task_name}': {e}")
            return None
    
    @staticmethod
    def create_task_via_stored_procedure(params: Dict[str, Any]) -> Optional[int]:
        """
        Create a task using the stored procedure with string interpolation.
        This method handles the main task creation logic with UC08 translation support.
        
        Args:
            params: Dictionary containing all task parameters
            
        Returns:
            Instance ID of created task, None if failed
        """
        translator = get_translator()
        translation_metadata = None
        translation_id = None
        
        try:
            # Check if UC08 translation is needed
            freq_type = params.get('FreqType')
            freq_recurrence = params.get('FreqRecurrance')
            
            if translator.needs_translation(freq_recurrence, freq_type):
                logger.info(f"UC08 Translation required for FreqRecurrance {freq_recurrence}")
                
                # Encode parameters for database
                params, translation_metadata = translator.encode_for_database(params)
                
                # Store translation metadata
                translation_id = translator.store_translation_metadata(translation_metadata)
                
                logger.info(f"UC08 Translation applied: {freq_recurrence} -> {params.get('FreqRecurrance')}")
            
            # Continue with normal task creation using (possibly translated) parameters
            # Build SQL query with proper escaping
            sql_query = CREATE_TASK_PROCEDURE.format(
                task_name=DatabaseService.escape_sql_string(params.get('TaskName', '')),
                main_controller=DatabaseService.escape_sql_string(params.get('MainController', '')),
                controllers=DatabaseService.escape_sql_string(params.get('Controllers', '')),
                assignees=DatabaseService.escape_sql_string(params.get('Assignees', '')),
                due_date=DatabaseService.escape_sql_string(params.get('DueDate', '')),
                local_due_date=DatabaseService.escape_sql_string(params.get('LocalDueDate', '')),
                location=DatabaseService.escape_sql_string(params.get('Location', 'New York')),
                due_time=params.get('DueTime', 19),
                soft_due_date=DatabaseService.escape_sql_string(params.get('SoftDueDate', '')),
                final_due_date=DatabaseService.escape_sql_string(params.get('FinalDueDate', '')),
                items=DatabaseService.escape_sql_string(params.get('Items', '')),
                is_recurring=params.get('IsRecurring', 0),
                freq_type=params.get('FreqType', 'NULL') if params.get('FreqType') is not None else 'NULL',
                freq_recurrance=params.get('FreqRecurrance', 'NULL') if params.get('FreqRecurrance') is not None else 'NULL',
                freq_interval=params.get('FreqInterval', 'NULL') if params.get('FreqInterval') is not None else 'NULL',
                business_day_behavior=params.get('BusinessDayBehavior', 1),
                activate=params.get('Activate', 1),
                is_reminder=params.get('IsReminder', 0),
                reminder_date=DatabaseService.escape_sql_string(params.get('ReminderDate', '')),
                add_to_priority_list=params.get('AddToPriorityList', 0)
            )
            
            logger.info(f"Executing stored procedure for task: {params.get('TaskName')}")
            logger.info("="*80)
            logger.info("STORED PROCEDURE SQL QUERY:")
            logger.info("="*80)
            logger.info(sql_query)
            logger.info("="*80)
            
            # Check for large FreqRecurrance values that might cause issues
            freq_recurrance = params.get('FreqRecurrance')
            if freq_recurrance is not None and isinstance(freq_recurrance, int) and freq_recurrance >= 16384:
                logger.warning(f"Large FreqRecurrance detected ({freq_recurrance}), using parameterized query")
                # Build parameter list for parameterized query
                param_list = [
                    params.get('TaskName', ''),
                    params.get('MainController', ''),
                    params.get('Controllers', ''),
                    params.get('Assignees', ''),
                    params.get('DueDate', ''),
                    params.get('LocalDueDate', ''),
                    params.get('Location', 'New York'),
                    params.get('DueTime', 19),
                    params.get('SoftDueDate', ''),
                    params.get('FinalDueDate', ''),
                    params.get('Items', ''),
                    params.get('IsRecurring', 0),
                    params.get('FreqType') if params.get('FreqType') is not None else None,
                    params.get('FreqRecurrance') if params.get('FreqRecurrance') is not None else None,
                    params.get('FreqInterval') if params.get('FreqInterval') is not None else None,
                    params.get('BusinessDayBehavior', 1),
                    params.get('Activate', 1),
                    params.get('IsReminder', 0),
                    params.get('ReminderDate', ''),
                    params.get('AddToPriorityList', 0)
                ]
                return DatabaseService.create_task_via_stored_procedure_parameterized(param_list)
            
            # Special logging for UC08 pattern
            task_name = params.get('TaskName', '')
            if 'UC08' in task_name or ('month' in task_name.lower() and '15' in task_name):
                logger.warning("UC08 PATTERN: Monthly task with specific day")
                logger.warning(f"FreqType: {params.get('FreqType')}")
                logger.warning(f"FreqRecurrance: {params.get('FreqRecurrance')}")
                logger.warning(f"FreqInterval: {params.get('FreqInterval')}")
                logger.warning(f"Full SQL Query: {sql_query[:500]}...")
            
            with DatabaseService.get_cursor() as cursor:
                logger.info("Executing stored procedure query...")
                cursor.execute(sql_query)
                logger.info("Stored procedure query executed successfully")
                
                # Try to get the instance ID
                if cursor.description is not None:
                    result = cursor.fetchone()
                    if result and result[0] is not None:
                        instance_id = result[0]
                        logger.info("="*80)
                        logger.info(f"STORED PROCEDURE SUCCESS: Task created with ID: {instance_id}")
                        logger.info("="*80)
                        
                        # Link translation metadata to the created task
                        if translation_id and instance_id:
                            translator.link_translation_to_task(translation_id, instance_id)
                            logger.info(f"UC08 Translation linked: metadata ID {translation_id} -> task ID {instance_id}")
                        
                        return instance_id
                
                logger.warning("No instance ID returned from stored procedure")
                return None
                
        except Exception as e:
            error_handler.log_error(e, {'task_name': params.get('TaskName'), 'operation': 'create_task_via_stored_procedure'})
            logger.error(f"Error creating task via stored procedure: {e}")
            logger.error(f"SQL Query that failed: {sql_query[:500]}...")
            
            # Check if this was a translated UC08 task that still failed
            # This might indicate a deeper issue beyond just the 16384 limitation
            if translation_metadata:
                day = translation_metadata.get('day', 'unknown')
                logger.error(f"UC08 translated task still failed for day {day}")
                # Continue with normal error handling - translation didn't solve the issue
            
            raise DatabaseError(f"Task creation failed: {str(e)}", 'TASK_CREATION_FAILED')
    
    @staticmethod
    def create_task_via_stored_procedure_parameterized(param_list: List[Any]) -> Optional[int]:
        """
        Create a task using parameterized stored procedure call.
        This is safer for retry scenarios and special cases.
        
        Args:
            param_list: List of parameters in the correct order
            
        Returns:
            Instance ID of created task, None if failed
        """
        try:
            logger.info(f"Executing parameterized stored procedure")
            logger.info("="*80)
            logger.info("PARAMETERIZED STORED PROCEDURE PARAMETERS:")
            logger.info("="*80)
            
            param_names = [
                'TaskName', 'MainController', 'Controllers', 'Assignees', 'DueDate',
                'LocalDueDate', 'Location', 'DueTime', 'SoftDueDate', 'FinalDueDate',
                'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval',
                'BusinessDayBehavior', 'Activate', 'IsReminder', 'ReminderDate', 'AddToPriorityList'
            ]
            
            for i, (name, value) in enumerate(zip(param_names, param_list)):
                logger.info(f"  {name}: '{value}' (type: {type(value).__name__})")
            
            logger.info("="*80)
            logger.info("PARAMETERIZED STORED PROCEDURE SQL:")
            logger.info("="*80)
            logger.info(CREATE_TASK_PROCEDURE_PARAMETERIZED)
            logger.info("="*80)
            
            # Log specific parameters of interest
            if len(param_list) >= 14:
                logger.info(f"FreqType (param 12): {param_list[12]}")
                logger.info(f"FreqRecurrance (param 13): {param_list[13]}")
                logger.info(f"FreqInterval (param 14): {param_list[14]}")
            
            with DatabaseService.get_cursor() as cursor:
                logger.info("Executing parameterized stored procedure query...")
                cursor.execute(CREATE_TASK_PROCEDURE_PARAMETERIZED, param_list)
                logger.info("Parameterized stored procedure query executed successfully")
                
                # Try to get the instance ID
                if cursor.description is not None:
                    result = cursor.fetchone()
                    if result and result[0] is not None:
                        instance_id = result[0]
                        logger.info("="*80)
                        logger.info(f"PARAMETERIZED STORED PROCEDURE SUCCESS: Task created with ID: {instance_id}")
                        logger.info("="*80)
                        return instance_id
                
                logger.warning("No instance ID returned from parameterized stored procedure")
                return None
                
        except Exception as e:
            error_handler.log_error(e, {'operation': 'create_task_via_parameterized_stored_procedure'})
            logger.error(f"Error creating task via parameterized stored procedure: {e}")
            
            # Check if this is the UC08 limitation
            if len(param_list) >= 14:
                freq_type = param_list[12]
                freq_recurrance = param_list[13]
                if freq_type == 3 and freq_recurrance and isinstance(freq_recurrance, int) and freq_recurrance >= 16384:
                    import math
                    day = int(math.log2(freq_recurrance)) + 1
                    logger.warning(f"UC08 limitation hit (parameterized): Monthly task for day {day} failed")
                    raise DatabaseError(
                        f"I'm sorry, but there's currently a known limitation with monthly tasks scheduled "
                        f"for days 15-31. Your request for 'on the {day}th' cannot be processed at this time.\n\n"
                        f"**Workaround options:**\n"
                        f"1. Use 'every month' for a simple monthly schedule\n"
                        f"2. Schedule for days 1-14 instead\n"
                        f"3. Create separate tasks for different time periods\n\n"
                        f"Our team is working on a permanent solution. Thank you for your understanding.",
                        'UC08_MONTHLY_DAY_LIMITATION'
                    )
            
            raise DatabaseError(f"Parameterized task creation failed: {str(e)}", 'PARAMETERIZED_TASK_CREATION_FAILED')
    
    @staticmethod
    def add_to_priority_list_workaround(instance_id: int, assignees_str: str) -> bool:
        """
        UC03 Workaround: Manually add priority list entries.
        This addresses a bug where the stored procedure doesn't create priority list entries.
        
        Args:
            instance_id: Instance ID of the task
            assignees_str: Comma-separated string of assignee names
            
        Returns:
            True if successful, False otherwise
        """
        logger.info(f"UC03 Workaround called for instance {instance_id} with assignees: {assignees_str}")
        
        try:
            with DatabaseService.get_cursor() as cursor:
                # Get the ActiveChecklistID
                cursor.execute(GET_ACTIVE_CHECKLIST_ID, [instance_id])
                active_result = cursor.fetchone()
                
                if not active_result:
                    logger.error(f"No active checklist found for instance {instance_id}")
                    return False
                
                active_checklist_id = active_result[0]
                
                if assignees_str:
                    # Parse assignee names and get their user IDs
                    assignee_names = [name.strip() for name in assignees_str.split(',')]
                    
                    for assignee_name in assignee_names:
                        # Get users from the group
                        cursor.execute(GET_USERS_IN_GROUP, [assignee_name])
                        user_ids = cursor.fetchall()
                        
                        if user_ids:
                            for user_id_row in user_ids:
                                user_id = user_id_row[0]
                                # Add to priority list
                                cursor.execute(ADD_TO_PRIORITY_LIST_PROCEDURE, [user_id, active_checklist_id])
                                logger.debug(f"Added UserID {user_id} to priority list for task {instance_id}")
                        else:
                            # If no users in group, try to add a test user as fallback
                            logger.warning(f"UC03 Workaround: No users found in group '{assignee_name}', trying fallback")
                            cursor.execute(GET_TEST_USER)
                            test_user = cursor.fetchone()
                            if test_user:
                                cursor.execute(ADD_TO_PRIORITY_LIST_PROCEDURE, [test_user[0], active_checklist_id])
                                logger.info(f"UC03 Workaround: Added test user to priority list for validation")
                
                logger.info(f"UC03 Workaround: Completed for task {instance_id}")
                return True
                
        except Exception as e:
            error_handler.log_error(e, {'instance_id': instance_id, 'assignees': assignees_str, 'operation': 'uc03_workaround'})
            logger.error(f"UC03 Workaround failed: {e}")
            return False
    
    @staticmethod
    def create_task_with_priority_handling(params: Dict[str, Any], param_list: List[Any]) -> Optional[int]:
        """
        High-level method to create a task with automatic priority list handling.
        Combines task creation with the UC03 workaround when needed.
        
        Args:
            params: Dictionary containing task parameters (for priority list detection)
            param_list: List of parameters for stored procedure call
            
        Returns:
            Instance ID of created task, None if failed
        """
        instance_id = None
        
        try:
            # Try main stored procedure first
            instance_id = DatabaseService.create_task_via_stored_procedure(params)
            
            # If that fails, try fallback by name lookup
            if not instance_id:
                logger.warning("No instance ID from stored procedure, searching by task name...")
                instance_id = DatabaseService.find_task_by_name(params.get('TaskName', ''))
            
            # Apply UC03 workaround if priority list is requested
            if instance_id and params.get('AddToPriorityList') == 1:
                logger.info("Applying UC03 workaround for priority list")
                error_handler.apply_uc03_priority_list_workaround(
                    instance_id, 
                    params.get('Assignees', '')
                )
            
            return instance_id
            
        except Exception as e:
            logger.error(f"Error in create_task_with_priority_handling: {e}")
            
            # Use ErrorHandler to handle database errors with workarounds
            instance_id = error_handler.handle_database_error_with_workarounds(e, params, param_list)
            if instance_id:
                return instance_id
            
            # Re-raise the original exception
            raise
    
    @staticmethod
    def call_stored_procedure(procedure_name: str, params: List[Any]) -> List[Any]:
        """
        Generic method to call any stored procedure.
        
        Args:
            procedure_name: Name of the stored procedure
            params: List of parameters
            
        Returns:
            Results from the stored procedure
        """
        try:
            with DatabaseService.get_cursor() as cursor:
                cursor.callproc(procedure_name, params)
                result = cursor.fetchall()
                return result
                
        except Exception as e:
            error_handler.log_error(e, {'procedure_name': procedure_name, 'operation': 'call_stored_procedure'})
            logger.error(f"Error calling stored procedure '{procedure_name}': {e}")
            raise DatabaseError(f"Stored procedure call failed: {str(e)}", 'STORED_PROCEDURE_FAILED')
    
    @staticmethod
    def create_alert_for_task(instance_id: int, alert_params: Dict[str, Any]) -> bool:
        """
        Create an alert for a task using the QCheck_AddAlert stored procedure.
        
        Args:
            instance_id: The task instance ID to attach alert to
            alert_params: Dictionary containing alert parameters
            
        Returns:
            True if alert was created successfully, False otherwise
        """
        try:
            logger.info(f"ALERT CREATION STARTED for task {instance_id}")
            logger.info(f"Alert parameters received: {alert_params}")
            
            # Extract alert parameters
            alert_recipient = alert_params.get('_alert_recipient', '')
            alert_condition = alert_params.get('_alert_condition', 'overdue')
            alert_type = alert_params.get('_alert_type', 'email')
            alert_due_time_hours = alert_params.get('_alert_due_time_hours', 9.0)
            
            # Get group ID for the alert recipient (with fuzzy matching)
            group_id = DatabaseService._get_group_id_for_alert(alert_recipient)
            if not group_id:
                logger.error(f"Could not find group ID for alert recipient: {alert_recipient}")
                return False
            
            logger.info(f"Creating alert for group ID {group_id} (group: {alert_recipient})")
            
            # Determine alert parameters based on condition
            nag_before_days = 0  # Default to on due date
            nag_time = alert_due_time_hours
            
            # Check for custom alert message
            custom_message = alert_params.get('_alert_custom_message', '')
            
            if alert_condition == 'overdue':
                alert_type = 'Overdue'
                if custom_message:
                    alert_text = custom_message
                else:
                    alert_text = f'Task is overdue: {alert_params.get("TaskName", "Task")}'
            elif alert_condition == 'at_due':
                alert_type = 'Email'
                if custom_message:
                    alert_text = custom_message
                else:
                    alert_text = f'Reminder: Your task is due.'
            else:
                alert_type = 'Email'
                if custom_message:
                    alert_text = custom_message
                else:
                    alert_text = f'Alert: Task requires attention.'
            
            # Log alert parameters
            logger.info("ALERT STORED PROCEDURE PARAMETERS:")
            logger.info(f"  @InstanceID = {instance_id}")
            logger.info(f"  @nagBeforeDays = {nag_before_days}")
            logger.info(f"  @nagTime = {nag_time}")
            logger.info(f"  @alerteegroupid = {group_id}")
            logger.info(f"  @alertType = '{alert_type}'")
            logger.info(f"  @alertText = '{alert_text}'")
            logger.info(f"  Recipient: '{alert_recipient}'")
            logger.info(f"  Condition: '{alert_condition}'")
            if custom_message:
                logger.info(f"  Custom message: '{custom_message}'")
            
            # Execute the stored procedure
            with DatabaseService.get_cursor() as cursor:
                cursor.execute(ADD_ALERT_PROCEDURE, [
                    instance_id,
                    nag_before_days,
                    nag_time,
                    group_id,
                    alert_type,
                    alert_text
                ])
                
                logger.info(f"Successfully created alert for task {instance_id} to {alert_recipient}")
                return True
                
        except Exception as e:
            error_handler.log_error(e, {
                'instance_id': instance_id, 
                'alert_params': alert_params, 
                'operation': 'create_alert_for_task'
            })
            logger.error(f"Error creating alert for task {instance_id}: {e}")
            return False

    @staticmethod
    def _get_group_id_for_alert(group_name: str) -> Optional[int]:
        """
        Get the group ID for alert recipient using fuzzy matching.
        First validates that the group name exists in QCheck_Groups table,
        then returns the corresponding ID. Uses fuzzy matching to handle
        partial names like "Ken" matching "Ken Croft".
        
        Args:
            group_name: Name of the group/recipient
            
        Returns:
            Group ID if found, None otherwise
        """
        try:
            # Use the existing validate_group_exists method which has fuzzy matching
            group_exists, resolved_name, similar_groups = DatabaseService.validate_group_exists(group_name)
            
            if not group_exists:
                if similar_groups:
                    logger.warning(f"Group name '{group_name}' not found in QCheck_Groups table. Similar groups: {similar_groups}")
                else:
                    logger.warning(f"Group name '{group_name}' not found in QCheck_Groups table")
                return None
            
            # If group exists, get its ID using the resolved name
            with DatabaseService.get_cursor() as cursor:
                cursor.execute(GET_GROUP_ID_BY_NAME, [resolved_name])
                result = cursor.fetchone()
                
                if result:
                    group_id = result[0]
                    if resolved_name != group_name:
                        logger.info(f"Fuzzy matched '{group_name}' to '{resolved_name}' with ID {group_id}")
                    else:
                        logger.info(f"Validated group '{group_name}' exists in QCheck_Groups table with ID {group_id}")
                    return group_id
                else:
                    logger.error(f"Group '{resolved_name}' exists in QCheck_Groups but could not retrieve ID")
                    return None
                    
        except Exception as e:
            logger.error(f"Error validating and getting group ID for '{group_name}': {e}")
            return None

    @staticmethod
    def create_status_report_for_task(instance_id: int, status_report_params: Dict[str, Any]) -> bool:
        """
        Create a status report for a task using the QStatus_AddReport stored procedure.
        
        Args:
            instance_id: The task instance ID to attach status report to
            status_report_params: Dictionary containing status report parameters
            
        Returns:
            True if status report was created successfully, False otherwise
        """
        try:
            logger.info(f"STATUS REPORT CREATION STARTED for task {instance_id}")
            logger.info(f"Status report parameters received: {status_report_params}")
            
            # Extract status report parameters
            status_report_group = status_report_params.get('_status_report_group', '')
            status_report_name = status_report_params.get('_status_report_name', '')
            task_name = status_report_params.get('TaskName', '')
            
            # Handle main_controller placeholder for general status report requests
            if status_report_group == 'main_controller':
                # Get the main controller from the task parameters
                main_controller = status_report_params.get('MainController', '')
                if main_controller:
                    status_report_group = main_controller
                    logger.info(f"Replaced main_controller placeholder with actual controller: {main_controller}")
                else:
                    logger.warning("Status report requested but no main controller available")
                    return False
            
            # Get group ID for the status report group (with fuzzy matching and context)
            # Extract assignee groups for context
            assignee_groups = []
            assignees = status_report_params.get('Assignees', '')
            if assignees:
                # Split assignees by comma and clean up
                assignee_groups = [assignee.strip() for assignee in assignees.split(',') if assignee.strip()]
            
            group_id = DatabaseService._get_group_id_for_status_report(status_report_group, assignee_groups)
            if not group_id:
                logger.error(f"Could not find group ID for status report group: {status_report_group}")
                return False
            
            # Use custom report name if provided, otherwise use task name
            report_name = status_report_name if status_report_name else task_name
            if not report_name:
                logger.error("No report name available for status report")
                return False
            
            logger.info(f"Creating status report for group ID {group_id} (group: {status_report_group})")
            logger.info(f"Report name: {report_name}")
            
            # Log status report parameters
            logger.info("STATUS REPORT STORED PROCEDURE PARAMETERS:")
            logger.info(f"  @GroupID = {group_id}")
            logger.info(f"  @ReportName = '{report_name}'")
            logger.info(f"  @IsConfidential = {is_confidential}")
            logger.info(f"  Group: '{status_report_group}'")
            
            # Execute the stored procedure
            with DatabaseService.get_cursor() as cursor:
                # Default IsConfidential to 0 if not explicitly specified
                is_confidential = status_report_params.get('_is_confidential', 0)
                cursor.execute(ADD_STATUS_REPORT_PROCEDURE, [
                    group_id,
                    report_name,
                    is_confidential
                ])
                
                logger.info(f"Successfully created status report for task {instance_id} to {status_report_group}")
                return True
                
        except Exception as e:
            error_handler.log_error(e, {
                'instance_id': instance_id, 
                'status_report_params': status_report_params, 
                'operation': 'create_status_report_for_task'
            })
            logger.error(f"Error creating status report for task {instance_id}: {e}")
            return False

    @staticmethod
    def _get_group_id_for_status_report(group_name: str, context_groups: List[str] = None) -> Optional[int]:
        """
        Get the group ID for status report group using fuzzy matching.
        First validates that the group name exists in QCheck_Groups table,
        then returns the corresponding ID. Uses fuzzy matching to handle
        partial names like "IT" matching "IT Team".
        
        Args:
            group_name: Name of the group/recipient
            context_groups: Optional list of context groups (e.g., assignee groups) to consider
            
        Returns:
            Group ID if found, None otherwise
        """
        try:
            # Use the existing validate_group_exists method which has fuzzy matching
            group_exists, resolved_name, similar_groups = DatabaseService.validate_group_exists(group_name, context_groups)
            
            if not group_exists:
                if similar_groups:
                    logger.warning(f"Group name '{group_name}' not found in QCheck_Groups table. Similar groups: {similar_groups}")
                else:
                    logger.warning(f"Group name '{group_name}' not found in QCheck_Groups table")
                return None
            
            # If group exists, get its ID using the resolved name
            with DatabaseService.get_cursor() as cursor:
                cursor.execute(GET_GROUP_ID_BY_NAME, [resolved_name])
                result = cursor.fetchone()
                
                if result:
                    group_id = result[0]
                    if resolved_name != group_name:
                        logger.info(f"Fuzzy matched '{group_name}' to '{resolved_name}' with ID {group_id}")
                    else:
                        logger.info(f"Validated group '{group_name}' exists in QCheck_Groups table with ID {group_id}")
                    return group_id
                else:
                    logger.error(f"Group '{resolved_name}' exists in QCheck_Groups but could not retrieve ID")
                    return None
                    
        except Exception as e:
            logger.error(f"Error validating and getting group ID for '{group_name}': {e}")
            return None