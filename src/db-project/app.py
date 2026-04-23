import oracledb
from flask import Flask, render_template, request, redirect, url_for, flash, session
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
    if 'role' in session:
        if session['role'] == 'manager':
            return redirect(url_for('manager_dashboard'))
        elif session['role'] == 'customer':
            return redirect(url_for('customer_dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        if 'manager_login' in request.form:
            session['role'] = 'manager'
            flash('Logged in as Manager successfully!', 'success')
            return redirect(url_for('manager_dashboard'))
        elif 'customer_login' in request.form:
            code = request.form.get('customer_code')
            if not code:
                flash('Please provide a Customer Code.', 'error')
                return redirect(url_for('login'))
            
            # Simple check if customer exists (Optional but recommended)
            conn = get_connection()
            if conn:
                try:
                    with conn.cursor() as cursor:
                        cursor.execute("SELECT code FROM Customers WHERE code = :code", code=code)
                        row = cursor.fetchone()
                        if row:
                            session['role'] = 'customer'
                            session['customer_code'] = row[0]
                            flash('Logged in as Customer successfully!', 'success')
                            return redirect(url_for('customer_dashboard'))
                        else:
                            flash('Customer code not found.', 'error')
                except oracledb.Error as e:
                    flash(f'Database error: {str(e)}', 'error')
                finally:
                    conn.close()
            return redirect(url_for('login'))
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully!', 'success')
    return redirect(url_for('login'))

@app.route('/manager_dashboard')
def manager_dashboard():
    if session.get('role') != 'manager':
        flash('Access denied. Managers only.', 'error')
        return redirect(url_for('login'))
    return render_template('manager_dashboard.html')

@app.route('/customer_dashboard')
def customer_dashboard():
    if session.get('role') != 'customer':
        flash('Access denied. Customers only.', 'error')
        return redirect(url_for('login'))
    
    customer_code = session.get('customer_code')
    teams = []
    locations = []
    installations = []
    
    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                # Fetch teams
                cursor.execute("SELECT name FROM Teams")
                teams = [row[0] for row in cursor.fetchall()]
                
                # Fetch customer's event locations
                cursor.execute("SELECT code, TREAT(VALUE(e) AS EventLocation_t).location.address || ', ' || TREAT(VALUE(e) AS EventLocation_t).location.city FROM EventLocations e WHERE DEREF(e.customer).code = :c", c=customer_code)
                locations = cursor.fetchall()
                
                # Fetch installations (both normal and promos)
                cursor.execute("SELECT name, cost, CASE WHEN TREAT(VALUE(i) AS Promo_t) IS NOT NULL THEN 'Promo' ELSE 'Normal' END AS type FROM Installations i")
                installations = cursor.fetchall()
        except oracledb.Error as e:
            flash(f'Error fetching dashboard data: {str(e)}', 'error')
        finally:
            conn.close()
            
    return render_template('customer_dashboard.html', teams=teams, locations=locations, installations=installations, customer_code=customer_code)

@app.route('/add_one_time_booking', methods=['POST'])
def add_one_time_booking():
    if session.get('role') != 'customer':
        return redirect(url_for('login'))
        
    booking_date = datetime.strptime(request.form['booking_date'], '%Y-%m-%d').date()
    duration = request.form['duration']
    team_name = request.form['team_name']
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
    return redirect(url_for('customer_dashboard'))

@app.route('/add_recurrent_booking', methods=['POST'])
def add_recurrent_booking():
    if session.get('role') != 'customer':
        return redirect(url_for('login'))
        
    booking_date = datetime.strptime(request.form['booking_date'], '%Y-%m-%d').date()
    duration = request.form['duration']
    team_name = request.form['team_name']
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
    return redirect(url_for('customer_dashboard'))

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
    return redirect(url_for('login'))

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
    return redirect(url_for('login'))

@app.route('/add_event_location', methods=['POST'])
def add_event_loc():
    if session.get('role') != 'customer':
        return redirect(url_for('login'))
        
    region = request.form['region']
    province = request.form['province']
    city = request.form['city']
    address = request.form['address']
    postal_code = request.form['postal_code']
    house_number = request.form['house_number']
    setup_time_estimate = request.form['setup_time_estimate']
    eq_capacity = request.form['eq_capacity']
    customer_code = session.get('customer_code')

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
    return redirect(url_for('customer_dashboard'))

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

@app.route('/add_installation', methods=['POST'])
def add_installation():
    if session.get('role') != 'manager':
        return redirect(url_for('login'))
        
    name = request.form['name']
    description = request.form['description']
    cost = request.form['cost']

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc('add_new_installation', [name, description, cost])
                conn.commit()
            flash('Installation added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding installation: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('manager_dashboard'))

@app.route('/add_promo_installation', methods=['POST'])
def add_promo_installation():
    if session.get('role') != 'manager':
        return redirect(url_for('login'))
        
    name = request.form['name']
    description = request.form['description']
    cost = request.form['cost']
    code = request.form['code']
    discont = request.form['discont']
    deadline = datetime.strptime(request.form['deadline'], '%Y-%m-%d').date()

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc('add_new_promo_installation', [name, description, cost, code, discont, deadline])
                conn.commit()
            flash('Promo Installation added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding promo installation: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('manager_dashboard'))

@app.route('/add_central_office', methods=['POST'])
def add_central_office():
    if session.get('role') != 'manager':
        return redirect(url_for('login'))
        
    name = request.form['name']
    region = request.form['region']
    province = request.form['province']
    city = request.form['city']
    address = request.form['address']

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.callproc('add_new_central_office', [name, region, province, city, address])
                conn.commit()
            flash('Central Office added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding central office: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('manager_dashboard'))

@app.route('/add_depot', methods=['POST'])
def add_depot():
    if session.get('role') != 'manager':
        return redirect(url_for('login'))
        
    name = request.form['name']
    region = request.form['region']
    province = request.form['province']
    city = request.form['city']
    address = request.form['address']
    central_office = request.form['central_office']
    
    municipalities_list = request.form.getlist('municipality_name[]')

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                # Get the Oracle types
                MunicipalityTable = conn.gettype('MUNICIPALITYTABLE')
                Municipality_t = conn.gettype('MUNICIPALITY_T')
                
                municipalities = MunicipalityTable.newobject()
                
                for muni_name in municipalities_list:
                    muni = Municipality_t.newobject()
                    muni.NAME = muni_name
                    municipalities.append(muni)
                    
                cursor.callproc(
                    'add_new_depot',
                    [name, region, province, city, address, central_office, municipalities]
                )
                conn.commit()
            flash('Depot added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding depot: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('manager_dashboard'))

@app.route('/add_team', methods=['POST'])
def add_team():
    if session.get('role') != 'manager':
        return redirect(url_for('login'))
        
    name = request.form['name']
    depot = request.form['depot']

    member_names = request.form.getlist('member_name[]')
    member_surnames = request.form.getlist('member_surname[]')
    member_dobs = request.form.getlist('member_dob[]')
    member_genders = request.form.getlist('member_gender[]')
    member_emails = request.form.getlist('member_email[]')
    member_phones = request.form.getlist('member_phone[]')

    conn = get_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                # Get the Oracle types
                MembersVarray = conn.gettype('MEMBERSVARRAY')
                Member_t = conn.gettype('MEMBER_T')
                Anagraphic_t = conn.gettype('ANAGRAPHIC_T')
                ContactInfo_t = conn.gettype('CONTACTINFO_T')
                
                members = MembersVarray.newobject()
                
                for i in range(len(member_names)):
                    anagraphic = Anagraphic_t.newobject()
                    anagraphic.NAME = member_names[i]
                    anagraphic.SURNAME = member_surnames[i]
                    anagraphic.DATE_OF_BIRTH = datetime.strptime(member_dobs[i], '%Y-%m-%d').date()
                    anagraphic.GENDER = member_genders[i]
                    
                    contact_info = ContactInfo_t.newobject()
                    contact_info.EMAIL = member_emails[i]
                    contact_info.PHONE = member_phones[i]
                    
                    member = Member_t.newobject()
                    member.ANAGRAPHIC = anagraphic
                    member.CONTACT_INFO = contact_info
                    
                    members.append(member)
                
                cursor.callproc('add_new_team', [name, depot, members])
                conn.commit()
            flash('Team added successfully!', 'success')
        except oracledb.Error as e:
            flash(f'Error adding team: {str(e)}', 'error')
        finally:
            conn.close()
    return redirect(url_for('manager_dashboard'))

if __name__ == '__main__':
    app.run(debug=True, port=5000)
