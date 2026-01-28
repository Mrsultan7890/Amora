"""Add call history table

Revision ID: 001
Revises: 
Create Date: 2024-01-28

"""
from alembic import op
import sqlalchemy as sa

def upgrade():
    op.execute("""
        CREATE TABLE IF NOT EXISTS call_history (
            id TEXT PRIMARY KEY,
            caller_id TEXT NOT NULL,
            callee_id TEXT NOT NULL,
            call_type TEXT NOT NULL,
            duration INTEGER DEFAULT 0,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (caller_id) REFERENCES users (id),
            FOREIGN KEY (callee_id) REFERENCES users (id)
        )
    """)

def downgrade():
    op.drop_table('call_history')