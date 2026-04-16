import oracledb
from flask import Flask, render_template, request, redirect, url_for, flash
import os

from datetime import datetime

import dotenv
dotenv.load_dotenv()  # Load environment variables from .env file

app = Flask(__name__)
app.secret_key = 'super_secret_key'

# check if environment variables are set. If not raise an error
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_DSN = os.getenv('DB_DSN')

def get_connection():
    # print(f"Attempting to connect with:")
    # print(f"  User: {DB_USER}")
    # print(f"  Password: {'*' * len(DB_PASSWORD) if DB_PASSWORD else 'NOT SET'}")
    # print(f"  DSN: {DB_DSN}")
    
    if not DB_USER or not DB_PASSWORD or not DB_DSN:
        print("ERROR: Missing environment variables!")
        return None
    
    try:
        return oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
    except oracledb.Error as e:
        print(f"Error connecting to DB: {e}")
        return None

@app.route('/')
def index():
    conn = get_connection()
    teams = []
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT name FROM Teams")
                rows = cursor.fetchall()
                teams = [row[0] for row in rows]
        except oracledb.Error as e:
            flash(f'Error fetching teams: {str(e)}', 'error')
        finally:
            conn.close()
    return render_template('index.html', teams=teams)

@app.route('/add_one_time_booking', methods=['POST'])
def add_one_time_booking():
    booking_date = datetime.strptime(request.form['booking_date'], '%Y-%m-%d').date()
    duration = request.form['duration']
    team_name = request.form['team_name']
    # customer_code = request.form['customer_code']
    installation_name = request.form['installation_name']
    event_location_code = request.form['event_location_code']

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc('add_new_one_time_booking', [
                    booking_date, duration, team_name, installation_name, event_location_code
                ])
                conn.commit()
            flash('One-time Booking added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding one-time booking: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('index'))

@app.route('/add_recurrent_booking', methods=['POST'])
def add_recurrent_booking():
    booking_date = datetime.strptime(request.form['booking_date'], '%Y-%m-%d').date()
    duration = request.form['duration']
    team_name = request.form['team_name']
    # customer_code = request.form['customer_code']
    installation_name = request.form['installation_name']
    event_location_code = request.form['event_location_code']
    interval = request.form['interval']
    n_times = request.form['n_times']

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc('add_new_recurrent_booking', [
                    booking_date, duration, team_name, installation_name, event_location_code, interval, n_times
                ])
                conn.commit()
            flash('Recurrent Booking added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding recurrent booking: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('index'))

@app.route('/add_individual_customer', methods=['POST'])
def add_individual_customer():
    code = request.form['code']
    email = request.form['email']
    phone = request.form['phone']
    name = request.form['name']
    surname = request.form['surname']
    dob = datetime.strptime(request.form['dob'], '%Y-%m-%d').date()
    gender = request.form['gender']

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc(
                    'add_new_individual_customer', 
                    [code, email, phone, name, surname, dob, gender]
                )
                conn.commit()
            flash('Individual Customer added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding customer: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('index'))

@app.route('/add_company_customer', methods=['POST'])
def add_company_customer():
    code = request.form['code']
    email = request.form['email']
    phone = request.form['phone']
    company_name = request.form['company_name']
    vat_number = request.form['vat_number']

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc(
                    'add_new_company_customer', 
                    [code, email, phone, company_name, vat_number]
                )
                conn.commit()
            flash('Company Customer added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding company: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('index'))

@app.route('/add_event_location', methods=['POST'])
def add_event_loc():
    region = request.form['region']
    province = request.form['province']
    city = request.form['city']
    address = request.form['address']
    postal_code = request.form['postal_code']
    house_number = request.form['house_number']
    setup_time_estimate = request.form['setup_time_estimate']
    eq_capacity = request.form['eq_capacity']
    customer_code = request.form['customer_code']

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc(
                    'add_event_location', 
                    [region, province, city, address, postal_code, house_number, setup_time_estimate, eq_capacity, customer_code]
                )
                conn.commit()
            flash('Event Location added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding event location: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('index'))

@app.route('/top_event_locations')
def top_event_locations():
    conn = get_connection()
    locations = []
    if conn:
        try:
            with conn.cursor() as cursor:
                out_cursor = conn.cursor()
                cursor.callproc('get_top_event_locations', [out_cursor])
                locations = out_cursor.fetchall()
        except oracledb.Error as e:
            flash(f'Error fetching top locations: {str(e)}', 'error')
        finally:
            conn.close()
    return render_template('top_locations.html', locations=locations)

@app.route('/view_teams_for_location', methods=['GET', 'POST'])
def view_teams_for_location():
    teams = []
    if request.method == 'POST':
        location_code = request.form['location_code']
        conn = get_connection()
        if conn:
            try:
                with conn.cursor() as cursor:
                    out_cursor = conn.cursor()
                    cursor.callproc('get_teams_for_location', [location_code, out_cursor])
                    teams = out_cursor.fetchall()
            except oracledb.Error as e:
                flash(f'Error fetching teams for location: {str(e)}', 'error')
            finally:
                conn.close()
    return render_template('view_teams.html', teams=teams)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
