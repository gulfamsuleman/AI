from django.contrib import admin
from .models import ChatUser, ChatHistory, Task, PendingTaskSession

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'user', 'due_date', 'due_time', 'priority', 'status', 'confidential')
    list_filter = ('priority', 'status', 'confidential', 'user')
    search_fields = ('title', 'description')

@admin.register(ChatUser)
class ChatUserAdmin(admin.ModelAdmin):
    list_display = ('id', 'name')
    search_fields = ('name',)

@admin.register(ChatHistory)
class ChatHistoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'timestamp')
    search_fields = ('user__name', 'user_message', 'bot_reply')
    list_filter = ('user',)

@admin.register(PendingTaskSession)
class PendingTaskSessionAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'created_at', 'updated_at')
    search_fields = ('user',)
