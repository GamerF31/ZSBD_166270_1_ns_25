import pandas as pd
import oracledb
from datetime import datetime

conn = oracledb.connect(user="inf2ns_hubaczp", password="Jakna2002", dsn="213.184.8.44:1521/orcl")
cursor = conn.cursor()

def validate_email(email):
    if '@' not in email:
        return False
    return True

def validate_balance(balance):
    if balance < 0:
        return False
    return True

def validate_date(date):
    if pd.to_datetime(date) > pd.to_datetime('today'):
        return False
    return True

def validate_bonus_status(status):
    valid_statuses = ['aktywny', 'nieaktywny', 'zużyty']
    if status not in valid_statuses:
        return False
    return True

def validate_payment_method(method):
    valid_methods = ['przelew', 'karta', 'paypal']
    if method not in valid_methods:
        return False
    return True

def validate_event_name(name):
    if not name or len(name.strip()) == 0:
        return False
    return True

def validate_event_status(status):
    valid_statuses = ['planowane', 'zakończone', 'anulowane']
    if status not in valid_statuses:
        return False
    return True

def validate_score(score):
    if isinstance(score, int) and score >= 0:
        return True
    return False

def validate_result_date(result_date):
    if pd.to_datetime(result_date) > pd.to_datetime('today'):
        return False
    return True

def validate_bet_amount(bet_amount):
    if isinstance(bet_amount, (int, float)) and bet_amount >= 0:
        return True
    return False

def validate_bet_type(bet_type):
    valid_bet_types = ['zwyciezca', 'remis', 'wynik dokladny']
    if bet_type not in valid_bet_types:
        return False
    return True

def validate_bet_odds(bet_odds):
    if isinstance(bet_odds, (int, float)) and bet_odds > 0:
        return True
    return False

def validate_bet_status(bet_status):
    valid_bet_statuses = ['oczekujacy', 'zrealizowany']
    if bet_status not in valid_bet_statuses:
        return False
    return True

df_klienci = pd.read_csv('klienci.csv')

cursor.execute("DELETE FROM proj_bonusy WHERE client_id IN (SELECT client_id FROM proj_klienci)")
conn.commit()

cursor.execute("DELETE FROM proj_platnosci WHERE client_id IN (SELECT client_id FROM proj_klienci)")
conn.commit()

cursor.execute("DELETE FROM proj_zaklady WHERE event_id IN (SELECT event_id FROM proj_wydarzenia)")
conn.commit()

cursor.execute("DELETE FROM proj_wyniki WHERE event_id IN (SELECT event_id FROM proj_wydarzenia)")
conn.commit()

cursor.execute("DELETE FROM proj_wydarzenia")
conn.commit()

cursor.execute("DELETE FROM proj_klienci")
conn.commit()

for index, row in df_klienci.iterrows():
    client_id = row['client_id']
    first_name = row['first_name']
    last_name = row['last_name']
    email = row['email']
    phone = row['phone']
    created_at = row['created_at']
    balance = row['balance']

    if not validate_email(email):
        continue

    if not validate_balance(balance):
        continue

    cursor.execute("SELECT COUNT(*) FROM proj_klienci WHERE client_id = :client_id", {'client_id': client_id})
    count = cursor.fetchone()[0]

    if count > 0:
        continue
    else:
        cursor.execute("""
            INSERT INTO proj_klienci (client_id, first_name, last_name, email, phone, created_at, balance)
            VALUES (:client_id, :first_name, :last_name, :email, :phone, TO_DATE(:created_at, 'YYYY-MM-DD'), :balance)
        """, client_id=client_id, first_name=first_name, last_name=last_name,
            email=email, phone=phone, created_at=created_at, balance=balance)

df_bonusy = pd.read_csv('bonusy.csv')

cursor.execute("DELETE FROM proj_bonusy")
conn.commit()

for index, row in df_bonusy.iterrows():
    bonus_id = row['bonus_id']
    client_id = row['client_id']
    bonus_amount = row['bonus_amount']
    bonus_type = row['bonus_type']
    bonus_status = row['bonus_status']
    start_date = row['start_date']
    end_date = row['end_date']

    if not validate_balance(bonus_amount):
        continue

    if not validate_bonus_status(bonus_status):
        continue

    if not validate_date(start_date) or not validate_date(end_date):
        continue

    cursor.execute("SELECT COUNT(*) FROM proj_bonusy WHERE bonus_id = :bonus_id", {'bonus_id': bonus_id})
    count = cursor.fetchone()[0]

    if count > 0:
        continue
    else:
        cursor.execute("""
            INSERT INTO proj_bonusy (bonus_id, client_id, bonus_amount, bonus_type, bonus_status, start_date, end_date)
            VALUES (:bonus_id, :client_id, :bonus_amount, :bonus_type, :bonus_status, TO_DATE(:start_date, 'YYYY-MM-DD'), TO_DATE(:end_date, 'YYYY-MM-DD'))
        """, bonus_id=bonus_id, client_id=client_id, bonus_amount=bonus_amount, bonus_type=bonus_type,
            bonus_status=bonus_status, start_date=start_date, end_date=end_date)

df_platnosci = pd.read_csv('platnosci.csv')

cursor.execute("DELETE FROM proj_platnosci")
conn.commit()

for index, row in df_platnosci.iterrows():
    payment_id = row['payment_id']
    client_id = row['client_id']
    payment_amount = row['payment_amount']
    payment_method = row['payment_method']
    payment_date = row['payment_date']

    if not validate_balance(payment_amount):
        continue

    if not validate_payment_method(payment_method):
        continue

    if not validate_date(payment_date):
        continue

    cursor.execute("""
        INSERT INTO proj_platnosci (payment_id, client_id, payment_amount, payment_method, payment_date)
        VALUES (:payment_id, :client_id, :payment_amount, :payment_method, TO_DATE(:payment_date, 'YYYY-MM-DD'))
    """, payment_id=payment_id, client_id=client_id, payment_amount=payment_amount,
        payment_method=payment_method, payment_date=payment_date)

df_wydarzenia = pd.read_csv('wydarzenia.csv')

cursor.execute("DELETE FROM proj_wydarzenia")
conn.commit()

for index, row in df_wydarzenia.iterrows():
    event_id = row['event_id']
    event_name = row['event_name']
    event_date = row['event_date']
    team1 = row['team1']
    team2 = row['team2']
    event_status = row['status']

    if not validate_event_name(event_name):
        continue

    if not validate_date(event_date):
        continue

    if not validate_event_status(event_status):
        continue

    cursor.execute("SELECT COUNT(*) FROM proj_wydarzenia WHERE event_id = :event_id", {'event_id': event_id})
    count = cursor.fetchone()[0]

    if count > 0:
        continue
    else:
        cursor.execute("""
            INSERT INTO proj_wydarzenia (event_id, event_name, event_date, team1, team2, STATUS) 
            VALUES (:event_id, :event_name, TO_DATE(:event_date, 'YYYY-MM-DD'), :team1, :team2, :event_status)
        """, event_id=event_id, event_name=event_name, event_date=event_date, team1=team1, team2=team2, event_status=event_status)

df_wyniki = pd.read_csv('wyniki.csv')

cursor.execute("DELETE FROM proj_wyniki")
conn.commit()

for index, row in df_wyniki.iterrows():
    result_id = row['result_id']
    event_id = row['event_id']
    team1_score = row['team1_score']
    team2_score = row['team2_score']
    result_date = row['result_date']

    if not validate_score(team1_score):
        continue

    if not validate_score(team2_score):
        continue

    if not validate_result_date(result_date):
        continue

    cursor.execute("SELECT COUNT(*) FROM proj_wydarzenia WHERE event_id = :event_id", {'event_id': event_id})
    count = cursor.fetchone()[0]

    if count == 0:
        continue

    cursor.execute("""
        INSERT INTO proj_wyniki (result_id, event_id, team1_score, team2_score, result_date)
        VALUES (:result_id, :event_id, :team1_score, :team2_score, TO_DATE(:result_date, 'YYYY-MM-DD'))
    """, result_id=result_id, event_id=event_id, team1_score=team1_score, team2_score=team2_score, result_date=result_date)

df_zaklady = pd.read_csv('zaklady.csv')

cursor.execute("DELETE FROM proj_zaklady")
conn.commit()

for index, row in df_zaklady.iterrows():
    bet_id = row['bet_id']
    client_id = row['client_id']
    event_id = row['event_id']
    bet_amount = row['bet_amount']
    bet_type = row['bet_type']
    bet_odds = row['bet_odds']
    bet_date = row['bet_date']
    bet_status = row['bet_status']

    if not validate_bet_amount(bet_amount):
        continue

    if not validate_bet_type(bet_type):
        continue

    if not validate_bet_odds(bet_odds):
        continue

    if not validate_bet_status(bet_status):
        continue

    cursor.execute("SELECT COUNT(*) FROM proj_wydarzenia WHERE event_id = :event_id", {'event_id': event_id})
    count = cursor.fetchone()[0]

    if count == 0:
        continue

    cursor.execute("""
        INSERT INTO proj_zaklady (bet_id, client_id, event_id, bet_amount, bet_type, bet_odds, bet_date, bet_status)
        VALUES (:bet_id, :client_id, :event_id, :bet_amount, :bet_type, :bet_odds, TO_DATE(:bet_date, 'YYYY-MM-DD'), :bet_status)
    """, bet_id=bet_id, client_id=client_id, event_id=event_id, bet_amount=bet_amount,
        bet_type=bet_type, bet_odds=bet_odds, bet_date=bet_date, bet_status=bet_status)

conn.commit()
cursor.close()
conn.close()

print("Dane zostały załadowane pomyślnie.")
