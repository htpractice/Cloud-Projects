#!/usr/bin/env python3
"""
Test script for LookMyShow Three-Tier Architecture
Run this to verify all components work before deployment
"""

import requests
import mysql.connector
import sys
import json
from config import DATABASE_CONFIG

class ThreeTierTester:
    def __init__(self):
        self.base_url = "http://localhost:5000"
        self.db_config = DATABASE_CONFIG
        self.passed_tests = 0
        self.total_tests = 0
    
    def test_database_connection(self):
        """Test Data Tier - Database Connection"""
        print("\n🗄️  Testing Data Tier (Database Connection)...")
        self.total_tests += 1
        
        try:
            conn = mysql.connector.connect(
                host=self.db_config.host,
                user=self.db_config.user,
                password=self.db_config.password,
                database=self.db_config.database
            )
            
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM events")
            event_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM bookings")
            booking_count = cursor.fetchone()[0]
            
            conn.close()
            
            print(f"✅ Database connected successfully")
            print(f"   📊 Events in database: {event_count}")
            print(f"   📊 Bookings in database: {booking_count}")
            self.passed_tests += 1
            return True
            
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            return False
    
    def test_api_health(self):
        """Test Application Tier - API Health"""
        print("\n🔧 Testing Application Tier (API Health)...")
        self.total_tests += 1
        
        try:
            response = requests.get(f"{self.base_url}/api/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(f"✅ API Health Check: {data.get('status', 'unknown')}")
                self.passed_tests += 1
                return True
            else:
                print(f"❌ API Health Check failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ API Health Check failed: {e}")
            return False
    
    def test_events_endpoint(self):
        """Test Application Tier - Events API"""
        print("\n📅 Testing Events API...")
        self.total_tests += 1
        
        try:
            response = requests.get(f"{self.base_url}/api/events", timeout=5)
            if response.status_code == 200:
                events = response.json()
                print(f"✅ Events API working: {len(events)} events found")
                if events:
                    print(f"   📝 Sample event: {events[0].get('title', 'N/A')}")
                self.passed_tests += 1
                return events
            else:
                print(f"❌ Events API failed: {response.status_code}")
                return None
        except Exception as e:
            print(f"❌ Events API failed: {e}")
            return None
    
    def test_booking_creation(self):
        """Test Application Tier - Booking Creation"""
        print("\n🎫 Testing Booking Creation...")
        self.total_tests += 1
        
        test_booking = {
            "event_id": 1,
            "user_email": "test@lookmyshow.com"
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/bookings",
                json=test_booking,
                timeout=5
            )
            
            if response.status_code == 201:
                result = response.json()
                print(f"✅ Booking created: {result.get('message', 'Success')}")
                self.passed_tests += 1
                return True
            else:
                print(f"❌ Booking creation failed: {response.status_code}")
                try:
                    error = response.json()
                    print(f"   Error: {error}")
                except:
                    print(f"   Response: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Booking creation failed: {e}")
            return False
    
    def test_bookings_retrieval(self):
        """Test Application Tier - Bookings Retrieval"""
        print("\n📋 Testing Bookings Retrieval...")
        self.total_tests += 1
        
        try:
            response = requests.get(f"{self.base_url}/api/bookings", timeout=5)
            if response.status_code == 200:
                bookings = response.json()
                print(f"✅ Bookings API working: {len(bookings)} bookings found")
                self.passed_tests += 1
                return True
            else:
                print(f"❌ Bookings retrieval failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Bookings retrieval failed: {e}")
            return False
    
    def test_frontend_files(self):
        """Test Presentation Tier - Frontend Files"""
        print("\n🎨 Testing Presentation Tier (Frontend Files)...")
        
        files_to_check = ['index.html', 'script.js', 'styles.css']
        
        for file in files_to_check:
            self.total_tests += 1
            try:
                with open(file, 'r') as f:
                    content = f.read()
                    if len(content) > 0:
                        print(f"✅ {file} exists and has content ({len(content)} chars)")
                        self.passed_tests += 1
                    else:
                        print(f"❌ {file} is empty")
            except FileNotFoundError:
                print(f"❌ {file} not found")
            except Exception as e:
                print(f"❌ Error reading {file}: {e}")
    
    def run_comprehensive_test(self):
        """Run all tests for three-tier architecture"""
        print("🚀 Starting LookMyShow Three-Tier Architecture Tests")
        print("=" * 60)
        
        # Test each tier
        db_ok = self.test_database_connection()
        
        if not db_ok:
            print("\n⚠️  Database tests failed. Please check your database connection.")
            print("   Make sure the database is running and accessible.")
            
        # Frontend tests (always run)
        self.test_frontend_files()
        
        print("\n🔄 Starting Flask app tests...")
        print("   Note: Make sure Flask app is running on localhost:5000")
        print("   Run: python app.py (in another terminal)")
        
        # API tests
        api_ok = self.test_api_health()
        
        if api_ok:
            self.test_events_endpoint()
            self.test_booking_creation()
            self.test_bookings_retrieval()
        else:
            print("   ⚠️  API tests skipped - Flask app not running")
            print("   To test API: run 'python app.py' in another terminal")
        
        # Final results
        self.print_test_summary()
    
    def print_test_summary(self):
        """Print test summary"""
        print("\n" + "=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)
        
        success_rate = (self.passed_tests / self.total_tests) * 100 if self.total_tests > 0 else 0
        
        print(f"✅ Passed: {self.passed_tests}/{self.total_tests} tests ({success_rate:.1f}%)")
        
        if success_rate >= 80:
            print("🎉 EXCELLENT! Your three-tier architecture is ready for deployment!")
            print("\n📋 Architecture Components Verified:")
            print("   🎨 Presentation Tier: Frontend files ready")
            print("   🔧 Application Tier: Flask API working")
            print("   🗄️  Data Tier: Database connection established")
        elif success_rate >= 60:
            print("⚠️  GOOD but needs some fixes before deployment.")
        else:
            print("❌ ISSUES DETECTED. Please fix problems before deployment.")
        
        print("\n🚀 Next Steps:")
        print("   1. Fix any failing tests")
        print("   2. Run: gcloud app deploy app.yaml")
        print("   3. Test the deployed application")

if __name__ == "__main__":
    tester = ThreeTierTester()
    tester.run_comprehensive_test() 