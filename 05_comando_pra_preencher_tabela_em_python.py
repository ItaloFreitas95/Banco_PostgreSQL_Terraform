#comandos para preencher um milhão de linhas#

import psycopg2

#configurações#
host = "terraform-20211124094554972000000001.ct0mibzi4y8l.us-east-2.rds.amazonaws.com"
dbname = "banco"
user = "admini"
password ="05060708"


conn = psycopg2.connect(
    host="terraform-20211124094554972000000001.ct0mibzi4y8l.us-east-2.rds.amazonaws.com",
    database="banco",
    user="admini",
    password="05060708")

cursor = conn.cursor()


for numero in range(0, 25000):
    cursor.execute("insert into tipos_conta_cliente (tipo_conta) values ('pf_poupança'), ('pf_corrente'), ('pj_poupança'), ('pj_corrente')")

conn.commit()
cursor.close()
conn.close()
