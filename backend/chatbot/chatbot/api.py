from dotenv import load_dotenv
load_dotenv()

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import os
import requests
from .models import ChatUser, ChatHistory, Task, Review, Plan, Reminder
from .serializers import TaskSerializer
import datetime
from dateutil.relativedelta import relativedelta

GROQ_API_KEY = os.getenv('GROQ_API_KEY')
GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions'

class ChatAPIView(APIView):
    def post(self, request):
        user_message = request.data.get('message')
        user_name = request.data.get('user')
        if not user_message:
            return Response({'error': 'No message provided.'}, status=status.HTTP_400_BAD_REQUEST)
        if not user_name:
            return Response({'error': 'No user provided.'}, status=status.HTTP_400_BAD_REQUEST)
        headers = {
            'Authorization': f'Bearer {GROQ_API_KEY}',
            'Content-Type': 'application/json',
        }
        # Fetch or create chat user
        chat_user, _ = ChatUser.objects.get_or_create(name=user_name)
        # Fetch recent chat history for context
        recent_history = ChatHistory.objects.filter(user=chat_user).order_by('-timestamp')[:10]
        history_messages = []
        for h in reversed(recent_history):
            history_messages.append({"role": "user", "content": h.user_message})
            history_messages.append({"role": "assistant", "content": h.bot_reply})
        # Add current user message
        history_messages.append({"role": "user", "content": user_message})
        # --- LLM prompt for task-to-database operation ---
        system_prompt = (
            "You are a helpful and friendly database assistant. "
            "The user can ask to add, update, delete, or show users, tasks, reviews, plans, or reminders. "
            "Interpret the following message and return a JSON with the action "
            "(add_user, show_users, update_user, delete_user, show_history, "
            "add_task, show_tasks, update_task, delete_task, "
            "add_review, show_reviews, update_review, delete_review, "
            "add_plan, show_plans, update_plan, delete_plan, "
            "add_reminder, show_reminders, update_reminder, delete_reminder) and relevant data. "
            "For tasks, always collect all fields: title, description, due_date, due_time, recurrence, priority, status, alert, soft_due, confidential. "
            "If any of these fields are missing or ambiguous, ask a clarifying question for each missing field, one at a time, before returning a JSON action. "
            "For reviews, support fields: title, description, review_date, status, confidential. "
            "For plans, support fields: title, description, plan_date, status, confidential. "
            "For reminders, support fields: title, description, remind_at, status, confidential. "
            "If the user says 'add confidential review', set confidential=true. "
            "If the user says 'high priority task', set priority=High. "
            "If the user says 'every week', set recurrence=weekly. "
            "If the user says 'morning', set due_time=10:00. "
            "If the user says 'add user his name', treat it as a request to create a user with the given name. "
            "Respond ONLY with a JSON object if you have all necessary information to perform the action. "
            "Otherwise, respond with a friendly clarifying question in plain text.\n"
            "Examples:\n"
            "User: Add user John\n"
            "Response: {\"action\": \"add_user\", \"name\": \"John\"}\n"
            "User: Add user his name is Sameer\n"
            "Response: {\"action\": \"add_user\", \"name\": \"Sameer\"}\n"
            "User: Add a task\n"
            "Response: What is the title of the task you want to add?\n"
            "User: The title is 'call client'\n"
            "Response: What is the description of the task?\n"
            "User: Description is 'call about project'\n"
            "Response: What is the due date for the task?\n"
            "User: Tomorrow\n"
            "Response: What is the due time for the task?\n"
            "User: 10am\n"
            "Response: What is the recurrence for the task?\n"
            "User: None\n"
            "Response: What is the priority for the task?\n"
            "User: High\n"
            "Response: What is the status for the task?\n"
            "User: Pending\n"
            "Response: Should the task have an alert?\n"
            "User: Yes\n"
            "Response: Should the task have a soft due date?\n"
            "User: No\n"
            "Response: Is the task confidential?\n"
            "User: Yes\n"
            "Response: {\"action\": \"add_task\", \"title\": \"call client\", \"description\": \"call about project\", \"due_date\": \"2025-07-04\", \"due_time\": \"10:00\", \"recurrence\": \"none\", \"priority\": \"High\", \"status\": \"pending\", \"alert\": true, \"soft_due\": false, \"confidential\": true}\n"
            "User: Add a review for project Alpha on Friday\n"
            "Response: {\"action\": \"add_review\", \"title\": \"project Alpha\", \"review_date\": \"2025-07-04\"}\n"
            "User: Add a plan for next quarter\n"
            "Response: {\"action\": \"add_plan\", \"title\": \"next quarter plan\", \"plan_date\": \"2025-10-01\"}\n"
            "User: Remind me to submit report at 5pm today\n"
            "Response: {\"action\": \"add_reminder\", \"title\": \"submit report\", \"remind_at\": \"2025-07-04T17:00:00\"}\n"
        )
        llm_payload = {
            'model': 'llama3-8b-8192',
            'messages': [
                {"role": "system", "content": system_prompt},
                *history_messages
            ]
        }
        # Call LLM for intent parsing
        llm_response = requests.post(GROQ_API_URL, headers=headers, json=llm_payload, timeout=30)
        llm_data = llm_response.json()
        if llm_response.status_code != 200 or 'choices' not in llm_data or not llm_data['choices']:
            return Response({'error': 'LLM error: ' + str(llm_data)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        import re
        import json as pyjson
        try:
            # Extract the first JSON object from the LLM response
            content = llm_data['choices'][0]['message']['content']
            match = re.search(r'\{[\s\S]*?\}', content)
            if match:
                llm_json = pyjson.loads(match.group(0))
                is_json_response = True
            else:
                llm_json = {}
                is_json_response = False
        except Exception as e:
            print("LLM raw response:", llm_data)  # Add this line for debugging
            # Log the full LLM response for debugging
            result = (
                "Sorry, I could not understand the AI's response. "
                "Please try rephrasing your request."
            )
            ChatHistory.objects.create(user=chat_user, user_message=user_message, bot_reply=str(result))
            return Response({'reply': result}, status=status.HTTP_200_OK)
        result = None
        action = llm_json.get('action') if is_json_response else None
        if not is_json_response:
            # LLM response is a clarifying question or plain text
            ChatHistory.objects.create(user=chat_user, user_message=user_message, bot_reply=content)
            return Response({'reply': content})
        # Determine which user to associate with the chat history
        if action in ['add_user', 'update_user', 'delete_user', 'show_history', 'add_task', 'show_tasks', 'update_task', 'delete_task']:
            name = llm_json.get('name', user_name)
            if name:
                chat_user, _ = ChatUser.objects.get_or_create(name=name)
            else:
                chat_user, _ = ChatUser.objects.get_or_create(name=user_name)
        else:
            chat_user, _ = ChatUser.objects.get_or_create(name=user_name)
        if action == 'add_user':
            name = llm_json.get('name')
            if not name:
                result = 'No name provided.'
            else:
                ChatUser.objects.get_or_create(name=name)
                result = f"User '{name}' added."
        elif action == 'show_users':
            users = list(ChatUser.objects.values_list('name', flat=True))
            result = f"Users: {', '.join(users)}"
        elif action == 'update_user':
            name = llm_json.get('name')
            new_name = llm_json.get('new_name')
            if not name or not new_name:
                result = 'Name or new_name missing.'
            else:
                updated = ChatUser.objects.filter(name=name).update(name=new_name)
                result = f"User '{name}' updated to '{new_name}'" if updated else f"User '{name}' not found."
        elif action == 'delete_user':
            name = llm_json.get('name')
            if not name:
                result = 'No name provided to delete.'
            else:
                deleted, _ = ChatUser.objects.filter(name=name).delete()
                if deleted:
                    result = f"User '{name}' and all their chat history deleted."
                    return Response({'reply': result})
                else:
                    result = f"User '{name}' not found."
        elif action == 'add_task':
            title = llm_json.get('title')
            if not title:
                result = 'No task title provided.'
            else:
                task_data = {k: v for k, v in llm_json.items() if k in ['title', 'description', 'due_date', 'due_time', 'recurrence', 'priority', 'status', 'alert', 'soft_due', 'confidential']}
                task_data['user'] = chat_user
                # Parse natural language date
                if 'due_date' in task_data:
                    parsed_date = parse_natural_date(task_data['due_date'])
                    if not parsed_date:
                        result = f"Invalid due_date: {task_data['due_date']} (must be YYYY-MM-DD or a known phrase like 'tomorrow')"
                        ChatHistory.objects.create(user=chat_user, user_message=user_message, bot_reply=str(result))
                        return Response({'reply': result})
                    task_data['due_date'] = parsed_date
                Task.objects.create(**task_data)
                result = f"Task '{title}' added for {chat_user.name}."
        elif action == 'show_tasks':
            user = chat_user
            tasks = Task.objects.filter(user=user)
            if not tasks:
                result = f"No tasks found for {user.name}."
            else:
                result = '\n'.join([
                    f"{'[CONFIDENTIAL] ' if t.confidential else ''}{t.title} | Due: {t.due_date} {t.due_time or ''} | Priority: {t.priority} | Status: {t.status} | Recurrence: {t.recurrence}" for t in tasks
                ])
        elif action == 'update_task':
            title = llm_json.get('title')
            if not title:
                result = 'No task title provided to update.'
            else:
                update_fields = {k: v for k, v in llm_json.items() if k in ['description', 'due_date', 'due_time', 'recurrence', 'priority', 'status', 'alert', 'soft_due', 'confidential']}
                updated = Task.objects.filter(user=chat_user, title=title).update(**update_fields)
                result = f"Task '{title}' updated for {chat_user.name}." if updated else f"Task '{title}' not found for {chat_user.name}."
        elif action == 'delete_task':
            title = llm_json.get('title')
            if not title:
                result = 'No task title provided to delete.'
            else:
                deleted, _ = Task.objects.filter(user=chat_user, title=title).delete()
                result = f"Task '{title}' deleted for {chat_user.name}." if deleted else f"Task '{title}' not found for {chat_user.name}."
        # --- Review actions ---
        elif action == 'add_review':
            title = llm_json.get('title')
            if not title:
                result = 'No review title provided.'
            else:
                review_data = {k: v for k, v in llm_json.items() if k in ['title', 'description', 'review_date', 'status', 'confidential']}
                review_data['user'] = chat_user
                Review.objects.create(**review_data)
                result = f"Review '{title}' added for {chat_user.name}."
        elif action == 'show_reviews':
            user = chat_user
            reviews = Review.objects.filter(user=user)
            if not reviews:
                result = f"No reviews found for {user.name}."
            else:
                result = '\n'.join([
                    f"{'[CONFIDENTIAL] ' if r.confidential else ''}{r.title} | Date: {r.review_date} | Status: {r.status}" for r in reviews
                ])
        elif action == 'update_review':
            title = llm_json.get('title')
            if not title:
                result = 'No review title provided to update.'
            else:
                update_fields = {k: v for k, v in llm_json.items() if k in ['description', 'review_date', 'status', 'confidential']}
                updated = Review.objects.filter(user=chat_user, title=title).update(**update_fields)
                result = f"Review '{title}' updated for {chat_user.name}." if updated else f"Review '{title}' not found for {chat_user.name}."
        elif action == 'delete_review':
            title = llm_json.get('title')
            if not title:
                result = 'No review title provided to delete.'
            else:
                deleted, _ = Review.objects.filter(user=chat_user, title=title).delete()
                result = f"Review '{title}' deleted for {chat_user.name}." if deleted else f"Review '{title}' not found for {chat_user.name}."
        # --- Plan actions ---
        elif action == 'add_plan':
            title = llm_json.get('title')
            if not title:
                result = 'No plan title provided.'
            else:
                plan_data = {k: v for k, v in llm_json.items() if k in ['title', 'description', 'plan_date', 'status', 'confidential']}
                plan_data['user'] = chat_user
                Plan.objects.create(**plan_data)
                result = f"Plan '{title}' added for {chat_user.name}."
        elif action == 'show_plans':
            user = chat_user
            plans = Plan.objects.filter(user=user)
            if not plans:
                result = f"No plans found for {user.name}."
            else:
                result = '\n'.join([
                    f"{'[CONFIDENTIAL] ' if p.confidential else ''}{p.title} | Date: {p.plan_date} | Status: {p.status}" for p in plans
                ])
        elif action == 'update_plan':
            title = llm_json.get('title')
            if not title:
                result = 'No plan title provided to update.'
            else:
                update_fields = {k: v for k, v in llm_json.items() if k in ['description', 'plan_date', 'status', 'confidential']}
                updated = Plan.objects.filter(user=chat_user, title=title).update(**update_fields)
                result = f"Plan '{title}' updated for {chat_user.name}." if updated else f"Plan '{title}' not found for {chat_user.name}."
        elif action == 'delete_plan':
            title = llm_json.get('title')
            if not title:
                result = 'No plan title provided to delete.'
            else:
                deleted, _ = Plan.objects.filter(user=chat_user, title=title).delete()
                result = f"Plan '{title}' deleted for {chat_user.name}." if deleted else f"Plan '{title}' not found for {chat_user.name}."
        # --- Reminder actions ---
        elif action == 'add_reminder':
            title = llm_json.get('title')
            if not title:
                result = 'No reminder title provided.'
            else:
                reminder_data = {k: v for k, v in llm_json.items() if k in ['title', 'description', 'remind_at', 'status', 'confidential']}
                reminder_data['user'] = chat_user
                Reminder.objects.create(**reminder_data)
                result = f"Reminder '{title}' added for {chat_user.name}."
        elif action == 'show_reminders':
            user = chat_user
            reminders = Reminder.objects.filter(user=user)
            if not reminders:
                result = f"No reminders found for {user.name}."
            else:
                result = '\n'.join([
                    f"{'[CONFIDENTIAL] ' if r.confidential else ''}{r.title} | Remind at: {r.remind_at} | Status: {r.status}" for r in reminders
                ])
        elif action == 'update_reminder':
            title = llm_json.get('title')
            if not title:
                result = 'No reminder title provided to update.'
            else:
                update_fields = {k: v for k, v in llm_json.items() if k in ['description', 'remind_at', 'status', 'confidential']}
                updated = Reminder.objects.filter(user=chat_user, title=title).update(**update_fields)
                result = f"Reminder '{title}' updated for {chat_user.name}." if updated else f"Reminder '{title}' not found for {chat_user.name}."
        elif action == 'delete_reminder':
            title = llm_json.get('title')
            if not title:
                result = 'No reminder title provided to delete.'
            else:
                deleted, _ = Reminder.objects.filter(user=chat_user, title=title).delete()
                result = f"Reminder '{title}' deleted for {chat_user.name}." if deleted else f"Reminder '{title}' not found for {chat_user.name}."
        elif action == 'show_history':
            name = llm_json.get('name', user_name)
            try:
                user = ChatUser.objects.get(name=name)
                history = ChatHistory.objects.filter(user=user).order_by('-timestamp')[:10]
                result = '\n'.join([f"You: {h.user_message}\nBot: {h.bot_reply}" for h in history]) or 'No history.'
            except ChatUser.DoesNotExist:
                result = f"User '{name}' not found."
        else:
            result = (
                "Hello! I can help you with these tasks: add user, show users, update user, delete user, show chat history, add task, show tasks, update task, delete task. "
                "Please try a request like 'Add a new user named John' or 'Add a confidential task to call client tomorrow morning'."
            )
        ChatHistory.objects.create(user=chat_user, user_message=user_message, bot_reply=str(result))
        return Response({'reply': result})

def parse_natural_date(date_str):
    today = datetime.date.today()
    if not date_str:
        return None
    s = date_str.strip().lower()
    if s == 'today':
        return today.isoformat()
    if s == 'tomorrow':
        return (today + datetime.timedelta(days=1)).isoformat()
    if s == 'yesterday':
        return (today - datetime.timedelta(days=1)).isoformat()
    if s.startswith('next week'):
        return (today + datetime.timedelta(weeks=1)).isoformat()
    # Add more patterns as needed
    # If already in YYYY-MM-DD, return as is
    try:
        datetime.datetime.strptime(date_str, '%Y-%m-%d')
        return date_str
    except Exception:
        return None
