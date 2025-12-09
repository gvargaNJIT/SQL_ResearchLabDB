import sqlite3
import sys
from pathlib import Path

class Database:
    def __init__(self, db_file='lab.db'):
        try:
            self.connection = sqlite3.connect(db_file)
            self.cursor = self.connection.cursor()
            self.cursor.execute("PRAGMA foreign_keys = ON")
            print(f"Successfully connected to {db_file}")
        except sqlite3.Error as e:
            print(f"Error connecting to database: {e}")
            sys.exit(1)
    
    def execute_query(self, query):
        try:
            self.cursor.execute(query)
            results = self.cursor.fetchall()
            columns = [desc[0] for desc in self.cursor.description]
            
            if not results:
                print("No results found.")
                return

            header = " | ".join(columns)
            print("\n" + header)
            print("-" * len(header))

            for row in results:
                print(" | ".join(str(value) if value is not None else "NULL" for value in row))
            
        except sqlite3.Error as e:
            print(f"Query error: {e}")
    
    def execute_nonquery(self, query):
        try:
            self.cursor.execute(query)
            self.connection.commit()
            print(f"Command successful.")
        except sqlite3.Error as e:
            self.connection.rollback()
            print(f"Command error: {e}")
    
    def print_help(self):
        print("Commands:\n")
        print("query - Execute a SELECT query\n")
        print("insert - Execute an INSERT statement\n")
        print("update - Execute an UPDATE statement\n")
        print("delete - Execute a DELETE statement\n")
        print("help - Show this help menu\n")
        print("exit - Exit the program\n")
        print("For examples, look at the tests/testQueries.sql\n")
    
    def run(self):
        print("\n" + "-"*60)
        print("RESEARCH LAB DATABASE MANAGEMENT SYSTEM")
        print("-"*60)
        print("Type 'help' for available commands or 'exit' to quit.")
        
        while True:
            try:
                command = input("\nEnter command: ").strip().lower()
                
                if command == 'exit':
                    print("Closing connection and exiting...")
                    break
                
                elif command == 'help':
                    self.print_help()
                
                elif command == 'query':
                    print("Enter your SELECT query:")
                    query = input("> ").strip()
                    if query.upper().startswith('SELECT'):
                        self.execute_query(query)
                    else:
                        print("Query must start with SELECT")
                
                elif command == 'insert':
                    print("Enter your INSERT statement:")
                    query = input("> ").strip()
                    if query.upper().startswith('INSERT'):
                        self.execute_nonquery(query)
                    else:
                        print("Statement must start with INSERT")
                
                elif command == 'update':
                    print("Enter your UPDATE statement:")
                    query = input("> ").strip()
                    if query.upper().startswith('UPDATE'):
                        self.execute_nonquery(query)
                    else:
                        print("Statement must start with UPDATE")
                
                elif command == 'delete':
                    print("Enter your DELETE statement:")
                    query = input("> ").strip()
                    if query.upper().startswith('DELETE'):
                        self.execute_nonquery(query)
                    else:
                        print("Statement must start with DELETE")
                
                else:
                    print(f"Unknown command: '{command}'. Type 'help' for available commands.")
            
            except KeyboardInterrupt:
                print("\n\nInterrupted. Type 'exit' to quit.")
            except Exception as e:
                print(f"An error occurred: {e}")
    
    def close(self):
        if self.connection:
            self.connection.close()
            print("Database connection closed.")

def main():
    db_file = 'lab.db'

    if not Path(db_file).exists():
        print(f"\nDatabase file '{db_file}' not found!")

    sql = Database(db_file)
    try:
        sql.run()
    finally:
        sql.close()

if __name__ == "__main__":
    main()