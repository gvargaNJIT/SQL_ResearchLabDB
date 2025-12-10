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

    def execute_query(self, table_name, pk_name, pk_value):
        try:
            sql = f"SELECT * FROM {table_name} WHERE {pk_name} = ?"
            self.cursor.execute(sql, (pk_value,))
            row = self.cursor.fetchone()
        
            if row is None:
                print("No matching record found.")
                return

            columns = [desc[0] for desc in self.cursor.description]
            print("" + " | ".join(columns))
            print("-" * 50)
            print(" | ".join(str(v) if v is not None else "NULL" for v in row))

            if table_name.upper() == "MEMBER":
                mem_id = row[columns.index("memID")]
                prefix = mem_id[0].lower()
            
                if prefix == "f":
                    child_table = "FACULTY"
                elif prefix == "s":
                    child_table = "STUDENT"
                elif prefix == "e":
                    child_table = "EXTCOLLAB"
                else:
                    print("Unknown member type; cannot fetch child table info.")
                    return

                self.cursor.execute(f"SELECT * FROM {child_table} WHERE memID = ?", (mem_id,))
                child_row = self.cursor.fetchone()
                if child_row:
                    child_columns = [desc[0] for desc in self.cursor.description]
                    print(f"--- {child_table} Info ---")
                    print(" | ".join(child_columns))
                    print("-" * 50)
                    print(" | ".join(str(v) if v is not None else "NULL" for v in child_row))

            return row
        except sqlite3.Error as e:
            print(f"Query error: {e}")
            return


    def execute_insert(self, table_name):
        try:
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            cols_info = self.cursor.fetchall()
            if not cols_info:
                print(f"Table '{table_name}' does not exist.")
                return

            print(f"Inserting into table: {table_name}")
            print("-" * 50)

            col_names = []
            values = []

            for cid, name, ctype, notnull, default, pk in cols_info:
                if pk == 1 and ctype.upper() in ("INTEGER", "INT"):
                    continue

                hint = ""
                if "date" in name.lower():
                    hint = "(YYYY-MM-DD)"
                if notnull:
                    hint += " [REQUIRED]"

                user_input = input(f"{name} {hint}: ").strip()
                if not user_input:
                    if notnull and default is None:
                        print(f"ERROR: '{name}' is required.")
                        return
                    values.append(None)
                else:
                    values.append(user_input)
                col_names.append(name)

            cols_str = ", ".join(col_names)
            qmarks = ", ".join(["?"] * len(col_names))
            sql = f"INSERT INTO {table_name} ({cols_str}) VALUES ({qmarks})"
            self.cursor.execute(sql, values)
            self.connection.commit()
            print(f"Inserted into {table_name}.")

            if table_name.upper() == "MEMBER":
                mem_id_index = next((i for i, c in enumerate(col_names) if c == "memID"), None)
                if mem_id_index is None:
                    print("Error: memID not captured.")
                    return
                mem_id = values[mem_id_index]

                prefix_map = {"f": "FACULTY", "s": "STUDENT", "e": "EXTCOLLAB"}
                child_table = prefix_map.get(mem_id[0].lower())
                if child_table:
                    assigned_projects = []
                    while True:
                        projID = input("Enter a project ID to assign this member (leave blank to finish): ").strip()
                        if not projID:
                            break
                        assigned_projects.append(projID)
                    if not assigned_projects:
                        print("Insert error: Member must be assigned to at least one project")
                        self.connection.rollback()
                        return
                    for projID in assigned_projects:
                        self.cursor.execute("INSERT INTO WORK_ON (memID, projID) VALUES (?, ?)", (mem_id, projID))
                    self.connection.commit()
                    print(f"Member {mem_id} assigned to projects: {', '.join(assigned_projects)}")

                    self.cursor.execute(f"PRAGMA table_info({child_table})")
                    child_cols_info = self.cursor.fetchall()
                    child_col_names = []
                    child_values = []
                    print(f"Completing {child_table} record:")
                    for cid, name, ctype, notnull, default, pk in child_cols_info:
                        if name == "memID":
                            child_col_names.append(name)
                            child_values.append(mem_id)
                            continue
                        user_input = input(f"{name}: ").strip()
                        if not user_input and notnull:
                            print(f"ERROR: '{name}' is required.")
                            return
                        child_col_names.append(name)
                        child_values.append(user_input if user_input else None)
                    cols = ", ".join(child_col_names)
                    qs = ", ".join(["?"] * len(child_col_names))
                    self.cursor.execute(f"INSERT INTO {child_table} ({cols}) VALUES ({qs})", child_values)
                    self.connection.commit()
                    print(f"Successfully inserted into {child_table}.")

        except Exception as e:
            print(f"Insert error: {e}")
            self.connection.rollback()

    def execute_delete(self, table_name, pk_name, pk_value):
        try:
            sql = f"DELETE FROM {table_name} WHERE {pk_name} = ?"
            self.cursor.execute(sql, (pk_value,))
            self.connection.commit()

            if self.cursor.rowcount == 0:
                print("No record deleted (id not found).")
            else:
                print("Record deleted successfully.")
        except sqlite3.Error as e:
            print(f"Delete error: {e}")

    def execute_update(self, table_name, pk_name, pk_value, updates: dict):
        try:
            if not updates:
                print("No fields to update.")
                return

            set_clause = ", ".join(f"{col} = ?" for col in updates.keys())
            sql = f"""
                UPDATE {table_name}
                SET {set_clause}
                WHERE {pk_name} = ?
            """

            values = list(updates.values()) + [pk_value]
            self.cursor.execute(sql, values)
            self.connection.commit()

            if self.cursor.rowcount == 0:
                print("No record updated (id not found).")
            else:
                print("Record updated successfully.")
        except sqlite3.Error as e:
            print(f"Update error: {e}")

    def execute_projMem(self):
        while True:
            print("-" * 50)
            print("Project and Member Management")
            print("-" * 50)
            print("")
            print("Press the number of the command you want:")
            print("1: Query a Member")
            print("2: Insert a Member")
            print("3: Delete a Member")
            print("4: Update a Member")
            print("5: Query a Project")
            print("6: Insert a Project")
            print("7: Delete a Project")
            print("8: Update a Project")
            print("9: Status of a Project")
            print("10: Members of a project of a specific grant")
            print("11: Mentorships on the same project")
            print("0: Exit back to main menu")
            query = input("> ").strip()

            if query == "1":
                print ("In the member table, which column would you like to query:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query:")
                valueID = input("> ").strip()
                self.execute_query(table_name='MEMBER', pk_name=columnID, pk_value=valueID)

            elif query == "2":
                self.execute_insert(table_name='MEMBER')
            
            elif query == "3":
                print("In the member table, which column would you like to query for deletion of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query for deletion of the tuple:")
                valueID = input("> ").strip()
                confirm = input("Are you sure you want to delete this record? (y/n): ").strip().lower()
                if confirm != "y":
                    print("Deletion cancelled.")
                    continue

                try:
                    self.cursor.execute("SELECT memID FROM MEMBER WHERE {} = ?".format(columnID), (valueID,))
                    row = self.cursor.fetchone()
                    if not row:
                        print("Member not found.")
                        continue
                    mem_id = row[0]
                    prefix = mem_id[0].lower()
                    self.cursor.execute("DELETE FROM WORK_ON WHERE memID = ?", (mem_id,))
                    if prefix == "f":
                        self.cursor.execute("SELECT COUNT(*) FROM PROJECT WHERE memID = ?", (mem_id,))
                        count = self.cursor.fetchone()[0]  
                        if count > 0:
                            print("Cannot delete: This faculty member is leading a project. Update project leadership before deletion.")
                        else:
                            self.cursor.execute("DELETE FROM FACULTY WHERE memID = ?", (mem_id,))
                    elif prefix == "s":
                        self.cursor.execute("DELETE FROM STUDENT WHERE memID = ?", (mem_id,))
                    elif prefix == "e":
                        self.cursor.execute("DELETE FROM EXTCOLLAB WHERE memID = ?", (mem_id,))
                    
                    self.cursor.execute("""
                        UPDATE MEMBER
                        SET mentorID = NULL,
                            mentorStartDate = NULL,
                            mentorEndDate = NULL
                        WHERE mentorID = ?
                        """, (mem_id,))

                    self.cursor.execute("DELETE FROM USES WHERE memID = ?", (mem_id,))
                    self.cursor.execute("DELETE FROM AUTHORED_BY WHERE memID = ?", (mem_id,))
                    self.cursor.execute(
                        "DELETE FROM PUBLICATION WHERE pubID IN (SELECT pubID FROM PUBLICATION "
                        "LEFT JOIN AUTHORED_BY USING(pubID) "
                        "GROUP BY pubID HAVING COUNT(AUTHORED_BY.memID) = 0)"
                    )
                    self.execute_delete(table_name='MEMBER', pk_name=columnID, pk_value=valueID)
        
                    self.connection.commit()
    
                except Exception as e:
                    self.connection.rollback()
                    print(f"Delete error: {e}")

            elif query == "4":
                print ("In the member table, which column would you like to update of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value identifies the row you want to update:")
                valueID = input("> ").strip()
                print("Which column do you want to change:")
                update_column = input("> ").strip()
                print(f"Enter the new value for {update_column}:")
                update_value = input("> ").strip()
                updateID = {update_column: update_value}
                self.execute_update(table_name='MEMBER', pk_name=columnID, pk_value=valueID, updates=updateID)

            elif query == "5":
                print ("In the project table, which column would you like to query:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query:")
                valueID = input("> ").strip()
                self.execute_query(table_name='PROJECT', pk_name=columnID, pk_value=valueID)

            elif query == "6":
                self.execute_insert(table_name='PROJECT')
            
            elif query == "7":
                print("In the project table, which column would you like to query for deletion of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query for deletion of the tuple:")
                valueID = input("> ").strip()

                confirm = input("Are you sure you want to delete this record? (y/n): ").strip().lower()
                if confirm != "y":
                    print("Deletion cancelled.")
                    continue

                try:
                    conn = self.connection if hasattr(self, "connection") else self.conn
                    cursor = conn.cursor()

                    cursor.execute("DELETE FROM WORK_ON WHERE projID = ?",(valueID,))

                    cursor.execute("SELECT grantID FROM FUNDED_BY WHERE projID = ?",(valueID,))
                    grants_to_check = [row[0] for row in cursor.fetchall()]
                    cursor.execute("DELETE FROM FUNDED_BY WHERE projID = ?",(valueID,))

                    for grantID in grants_to_check:
                        cursor.execute("SELECT COUNT(*) FROM FUNDED_BY WHERE grantID = ?",(grantID,))
                        if cursor.fetchone()[0] == 0:
                            cursor.execute("DELETE FROM GRANT WHERE grantID = ?",(grantID,))

                    self.execute_delete(table_name='PROJECT', pk_name=columnID, pk_value=valueID)

                    conn.commit()

                except Exception as e:
                    conn.rollback()
                    print(f"Delete error: {e}")

            elif query == "8":
                print ("In the project table, which column would you like to update of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value identifies the row you want to update:")
                valueID = input("> ").strip()
                print("Which column do you want to change:")
                update_column = input("> ").strip()
                print(f"Enter the new value for {update_column}:")
                update_value = input("> ").strip()
                updateID = {update_column: update_value}
                self.execute_update(table_name='PROJECT', pk_name=columnID, pk_value=valueID, updates=updateID)
            
            elif query == "9":
                print("Enter the project ID:")
                projID = input("> ").strip()
    
                try:
                    sql = "SELECT statusProj FROM PROJECT WHERE projID = ?"
                    self.cursor.execute(sql, (projID,))
                    row = self.cursor.fetchone()
        
                    if row is None:
                        print(f"No project found with ID {projID}.")
                    else:
                        status = row[0]
                        print(f"Project {projID} status: {status}")
    
                except sqlite3.Error as e:
                    print(f"Query error: {e}")
            
            elif query == "10":
                print("Enter the grant ID:")
                grantID = input("> ").strip()

                try:
                    sql = ""
                    self.cursor.execute(sql, (grantID,))
                    rows = self.cursor.fetchall()
                    if not rows:
                        print(f"No grant found with ID {grantID}.")
                    else:
                        for row in rows:
                            projID, member = row
                            print(f"Grant {grantID} funding Project {projID} Member: {member}")
                except sqlite3.Error as e:
                    print(f"Query error: {e}")

            elif query == "11":
                print("Enter the proj ID:")
                projID = input("> ").strip()

                try:
                    sql = ""
                    self.cursor.execute(sql, (projID,))
                    rows = self.cursor.fetchall()
                    if not rows:
                        print(f"No mentorships with the members found with the same ID {projID}.")
                    else:
                        for row in rows:
                            mentor, mentee = row
                            print(f"Project {projID} shares member {mentor} who mentors {mentee}")
                except sqlite3.Error as e:
                    print(f"Query error: {e}")

            elif query == "0":
                break
            else:
                print("Option not implemented yet.")

    def execute_equipment(self):
        while True:
            print("-" * 50)
            print("Equipment Usage Tracking")
            print("-" * 50)
            print("")
            print("Press the number of the command you want:")
            print("1: Query an Equipment")
            print("2: Insert an Equipment")
            print("3: Delete an Equipment")
            print("4: Update an Equipment")
            print("5: Query an Equipment Usage")
            print("6: Insert an Equipment Usage")
            print("7: Delete an Equipment Usage")
            print("8: Update an Equipment Usage")
            print("9: Status of an Equipment")
            print("10: Members with given equipment and their projects")
            print("0: Exit back to main menu")
            query = input("> ").strip()

            if query == "1":
                print ("In the equipment table, which column would you like to query:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query:")
                valueID = input("> ").strip()
                self.execute_query(table_name='EQUIPMENT', pk_name=columnID, pk_value=valueID)

            elif query == "2":
                self.execute_insert(table_name='EQUIPMENT')
            
            elif query == "3":
                print ("In the equipment table, which column would you like to query for deletion of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query for deletion of the tuple:")
                valueID = input("> ").strip()
                confirm = input("Are you sure you want to delete this record? (y/n): ").strip().lower()
                if confirm != "y":
                    print("Deletion cancelled.")
                    continue

                conn = self.connection if hasattr(self, "connection") else self.conn
                cursor = conn.cursor()
                cursor.execute(f"DELETE FROM USES WHERE equipID IN (SELECT equipID FROM EQUIPMENT WHERE {columnID} = ?)", (valueID,))
                self.execute_delete(table_name='EQUIPMENT', pk_name=columnID, pk_value=valueID)

            elif query == "4":
                print ("In the equipment table, which column would you like to update of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value identifies the row you want to update:")
                valueID = input("> ").strip()
                print("Which column do you want to change:")
                update_column = input("> ").strip()
                print(f"Enter the new value for {update_column}:")
                update_value = input("> ").strip()
                updateID = {update_column: update_value}
                self.execute_update(table_name='EQUIPMENT', pk_name=columnID, pk_value=valueID, updates=updateID)

            elif query == "5":
                print ("In the usage table, which column would you like to query:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query:")
                valueID = input("> ").strip()
                self.execute_query(table_name='USES', pk_name=columnID, pk_value=valueID)

            elif query == "6":
                self.execute_insert(table_name='USES')
            
            elif query == "7":
                print ("In the usage table, which column would you like to query for deletion of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value would you like to query for deletion of the tuple:")
                valueID = input("> ").strip()
                confirm = input("Are you sure you want to delete this record? (y/n): ").strip().lower()
                if confirm != "y":
                    print("Deletion cancelled.")
                    continue
                self.execute_delete(table_name='USES', pk_name=columnID, pk_value=valueID)

            elif query == "8":
                print ("In the usage table, which column would you like to update of the tuple:")
                columnID = input("> ").strip()
                print(f"In {columnID}, what value identifies the row you want to update:")
                valueID = input("> ").strip()
                print("Which column do you want to change:")
                update_column = input("> ").strip()
                print(f"Enter the new value for {update_column}:")
                update_value = input("> ").strip()
                updateID = {update_column: update_value}
                self.execute_update(table_name='USES', pk_name=columnID, pk_value=valueID, updates=updateID)
            
            elif query == "9":
                print("Enter the equipment ID:")
                equipID = input("> ").strip()
    
                try:
                    sql = "SELECT status FROM EQUIPMENT WHERE equipID = ?"
                    self.cursor.execute(sql, (equipID,))
                    row = self.cursor.fetchone()
        
                    if row is None:
                        print(f"No equipment found with ID {equipID}.")
                    else:
                        status = row[0]
                        print(f"Equipment {equipID} status: {status}")
    
                except sqlite3.Error as e:
                    print(f"Query error: {e}")
            
            elif query == "10":
                print("Enter the equipment ID:")
                equipID = input("> ").strip()

                try:
                    sql = ""
                    self.cursor.execute(sql, (equipID,))
                    rows = self.cursor.fetchall()
                    if not rows:
                        print(f"No equipment found with ID {equipID}.")
                    else:
                        for row in rows:
                            projID, member = row
                            print(f"Member {member} on project {projID} is using equipment {equipID}")
                except sqlite3.Error as e:
                    print(f"Query error: {e}")

            elif query == "0":
                break
            else:
                print("Option not implemented yet.")

    def execute_grant(self):
        while True:
            print("-" * 50)
            print("Grant and Publication Reporting")
            print("-" * 50)
            print("")
            print("Press the number of the command you want:")
            print("1: Members with highest amount of publications")
            print("2: Average number of student publications given major")
            print("3: Projects that were active and funded by a grant given a specific amount of time")
            print("4: Three prolific members who worked on a project by a given grant")
            print("0: Exit back to main menu")
            query = input("> ").strip()

            if query == "1":
                print("How many of the top members:")
                num = input("> ").strip()

                try:
                    sql = ""
                    self.cursor.execute(sql, (num,))
                    rows = self.cursor.fetchall()

                    if not rows:
                        print("No members found.")
                    else:
                        for row in rows:
                            member_name, pub_count = row
                            print(f"{member_name} has {pub_count} publications")

                except sqlite3.Error as e:
                    print(f"Query error: {e}")

            elif query == "2":
                print("Which major would you like the average students from:")
                major = input("> ").strip()
                try:
                    sql = ""
                    self.cursor.execute(sql)
                    rows = self.cursor.fetchall()
                    if not rows:
                        print("No data found.")
                    else:
                        for row in rows:
                            avg_pub = row
                            print(f"Major {major} has an average of {avg_pub} student publications")
                except sqlite3.Error as e:
                    print(f"Query error: {e}")

            elif query == "3":
                print("Enter start date (YYYY-MM-DD):")
                start_date = input("> ").strip()
                print("Enter end date (YYYY-MM-DD):")
                end_date = input("> ").strip()
                try:
                    sql = ""
                    self.cursor.execute(sql, (start_date, end_date))
                    rows = self.cursor.fetchall()
                    if not rows:
                        print("No projects found.")
                    else:
                        for row in rows:
                            projID, grantID = row
                            print(f"Project {projID} was funded by grant {grantID}")
                except sqlite3.Error as e:
                    print(f"Query error: {e}")

            elif query == "4":
                print("Enter grant ID:")
                grantID = input("> ").strip()
                try:
                    sql = ""
                    self.cursor.execute(sql, (grantID,))
                    rows = self.cursor.fetchall()
                    if not rows:
                        print("No members found.")
                    else:
                        for row in rows:
                            member_name, pub_count = row
                            print(f"Member {member_name} contributed to projects funded by grant {grantID} ({pub_count} publications)")
                except sqlite3.Error as e:
                    print(f"Query error: {e}")

            elif query == "0":
                break
            else:
                print("Option not implemented yet.")

    def run(self):
        print("-" * 50)
        print("Research Lab Database")
        print("-" * 50)
        print("")
        print("Press the number of the menu you want:")
        print("1: Project and Member Management")
        print("2: Equipment Usage Tracking")
        print("3: Grant and Publication Reporting")
        print("0: Exit program")
        
        while True:
            try:
                command = input("Enter menu: ").strip().lower()
                
                if command == "0":
                    print("Closing connection and exiting...")
                    break
                
                elif command == "1":
                    self.execute_projMem()
                
                elif command == "2":
                    self.execute_equipment()
                
                elif command == "3":
                    self.execute_grant()

                else:
                    print("Option not implemented yet.")
            
            except KeyboardInterrupt:
                print("Interrupted. Type '0' to quit.")
            except Exception as e:
                print(f"An error occurred: {e}")
    
    def close(self):
        if self.connection:
            self.connection.close()
            print("Database connection closed.")

def main():
    db_file = 'lab.db'

    if not Path(db_file).exists():
        print(f"Database file '{db_file}' not found!")

    sql = Database(db_file)
    try:
        sql.run()
    finally:
        sql.close()

if __name__ == "__main__":
    main()   
