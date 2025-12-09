import sqlite3
import re
import os

def extract_triggers(sql_content):
    triggers = []

    pattern = r'CREATE TRIGGER\s+(\w+).*?END;'
    matches = re.finditer(pattern, sql_content, re.DOTALL | re.IGNORECASE)
    
    for match in matches:
        trigger_name = match.group(1)
        full_trigger = match.group(0)
        triggers.append((trigger_name, full_trigger))
    
    return triggers

def clean_sql_for_sqlite(sql_content):
    sql_content = re.sub(
        r',?\s*CHECK\s*\([^)]*REGEXP[^)]*\)',
        '',
        sql_content,
        flags=re.IGNORECASE
    )
    sql_content = re.sub(r'VARCHAR\(\d+\)', 'TEXT', sql_content)
    sql_content = re.sub(r'CHAR\(\d+\)', 'TEXT', sql_content)
    sql_content = re.sub(r'\bTINYINT\b', 'INTEGER', sql_content, flags=re.IGNORECASE)
    sql_content = re.sub(r'\bSMALLINT\b', 'INTEGER', sql_content, flags=re.IGNORECASE)
    sql_content = re.sub(
        r'\s*ON\s+(DELETE|UPDATE)\s+(SET\s+NULL|CASCADE|NO\s+ACTION|RESTRICT)',
        '',
        sql_content,
        flags=re.IGNORECASE
    )
    
    return sql_content

def extract_create_table_statements(sql_content):
    pattern = r'CREATE\s+TABLE\s+(\w+)\s*\((.*?)\);'
    matches = re.finditer(pattern, sql_content, re.DOTALL | re.IGNORECASE)
    
    statements = []
    for match in matches:
        table_name = match.group(1)
        table_body = match.group(2)
        statement = f"CREATE TABLE {table_name} ({table_body});"
        statements.append((table_name, statement))
    
    return statements

def load_database():
    print("-" * 60)
    print("LOADING DATABASE")
    print("-" * 60)

    if os.path.exists('lab.db'):
        print("\nRemoving existing lab.db...")
        os.remove('lab.db')

    conn = sqlite3.connect('lab.db')
    cursor = conn.cursor()
    cursor.execute("PRAGMA foreign_keys = OFF")

    print("\n[1/4] Reading schema file...")
    try:
        with open('sql/sqlTables.sql', 'r') as f:
            schema = f.read()
    except FileNotFoundError:
        print("ERROR: sql/sqlTables.sql not found!")
        return

    print("[2/4] Extracting triggers...")
    triggers = extract_triggers(schema)
    print(f"   Found {len(triggers)} triggers")
    
    print("\n[3/4] Creating tables...")
    schema_clean = clean_sql_for_sqlite(schema)
    table_statements = extract_create_table_statements(schema_clean)
    
    created_tables = []
    for table_name, statement in table_statements:
        try:
            cursor.execute(statement)
            created_tables.append(table_name)
            print(f"SUCCESS: {table_name}")
        except sqlite3.Error as e:
            print(f"FAIL: {table_name}: {e}")
    
    conn.commit()
    print(f"   Created {len(created_tables)} tables")
    
    print("\n[4/4] Loading data...")
    try:
        with open('sql/sampleData.sql', 'r') as f:
            data = f.read()
    except FileNotFoundError:
        print("ERROR: sql/sampleData.sql not found!")
        return
    
    data_clean = clean_sql_for_sqlite(data)
    statements = re.split(r';\s*\n', data_clean)
    
    success = 0
    for statement in statements:
        statement = statement.strip()
        if statement and statement.upper().startswith(('INSERT', 'UPDATE')):
            try:
                cursor.execute(statement)
                success += 1
            except sqlite3.Error:
                pass
    
    conn.commit()
    cursor.execute("PRAGMA foreign_keys = ON")
    print(f"Executed {success} statements")
    
    print("\n" + "-" * 60)
    print("DATABASE SUMMARY")
    print("-" * 60)
    for table_name in created_tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"   {table_name:.<20} {count:>3} rows")
    
    print("\n" + "-" * 60)
    print("LOADING TRIGGERS")
    print("-" * 60)
    
    trigger_count = 0
    for trigger_name, trigger_sql in triggers:
        try:
            cursor.execute(trigger_sql)
            trigger_count += 1
            print(f"SUCCESS: {trigger_name}")
        except sqlite3.Error as e:
            print(f"FAIL: {trigger_name}: {e}")
    
    conn.commit()
    conn.close()
    
    print(f"\nLoaded {trigger_count} triggers")
    print("\n" + "-" * 60)
    print("Done. Run: python3 main.py")
    print("-" * 60 + "\n")

if __name__ == "__main__":
    load_database()