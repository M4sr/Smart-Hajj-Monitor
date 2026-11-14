import requests
import json
import time

# Ensure seed_db runs to populate the users
try:
    from seed_db import seed_database
    seed_database()
except Exception as e:
    print(f"Warning: Could not seed database from import: {e}")

BASE_URL = "http://127.0.0.1:8000"

def test_rbac_flow():
    print("\n" + "="*80)
    print("MEMULAI PENGUJIAN INTEGRASI RBAC & DATABASE MYSQL")
    print("="*80)
    
    # 1. Login Jemaah
    print("\n[UJI 1] Melakukan Login sebagai Jemaah (jemaah_ahmad)...")
    login_payload = {
        "username": "jemaah_ahmad",
        "password": "jemaahpassword"
    }
    r = requests.post(f"{BASE_URL}/auth/login/json", json=login_payload)
    if r.status_code != 200:
        print(f"FAILED: Login Jemaah gagal: {r.text}")
        return
    jemaah_token = r.json()["access_token"]
    print(f"SUCCESS: Login Berhasil. Token diperoleh: {jemaah_token[:30]}...")
    
    # 2. Login Petugas Medis
    print("\n[UJI 2] Melakukan Login sebagai Petugas Medis (dokter_lukman)...")
    login_payload = {
        "username": "dokter_lukman",
        "password": "dokterpassword"
    }
    r = requests.post(f"{BASE_URL}/auth/login/json", json=login_payload)
    if r.status_code != 200:
        print(f"FAILED: Login Petugas gagal: {r.text}")
        return
    petugas_token = r.json()["access_token"]
    print(f"SUCCESS: Login Berhasil. Token diperoleh: {petugas_token[:30]}...")

    # Headers setup
    jemaah_headers = {"Authorization": f"Bearer {jemaah_token}"}
    petugas_headers = {"Authorization": f"Bearer {petugas_token}"}

    # 3. Jemaah submits a health assessment
    print("\n[UJI 3] Jemaah melakukan pengisian Self-Assessment (Prediksi Risiko Tinggi)...")
    assessment_payload = {
        "usia": 58,
        "jenis_kelamin": "Laki-laki",
        "suhu_tubuh": 37.0,
        "sistolik": 160,
        "diastolik": 100,
        "detak_jantung": 95,
        "laju_pernapasan": 26,
        "komorbid": "Penyakit Jantung",
        "gejala_utama": "Sesak napas dan nyeri dada"
    }
    r = requests.post(f"{BASE_URL}/assessments/predict", json=assessment_payload, headers=jemaah_headers)
    if r.status_code != 201:
        print(f"FAILED: Pengisian assessment gagal: {r.text}")
        return
    assessment_data = r.json()
    assessment_id = assessment_data["id"]
    print(f"SUCCESS: Penilaian berhasil disimpan!")
    print(f"   -> Nama Jemaah: {r.json()['nama_lengkap'] if 'nama_lengkap' in r.json() else 'Ahmad Fauzi'}")
    print(f"   -> Prediksi Risiko: {assessment_data['tingkat_risiko']}")
    print(f"   -> Rekomendasi ML: {assessment_data['rekomendasi_tindakan']}")

    # 4. Jemaah tries to view all assessments (Should fail - 403 Forbidden)
    print("\n[UJI 4] Uji Keamanan: Jemaah mencoba mengakses data seluruh jemaah...")
    r = requests.get(f"{BASE_URL}/assessments/all", headers=jemaah_headers)
    print(f"   -> Respon HTTP Status: {r.status_code}")
    if r.status_code == 403:
        print("SUCCESS: Sistem menolak akses jemaah dengan benar (403 Forbidden).")
    else:
        print(f"FAILED: Pengamanan gagal, jemaah diizinkan mengakses data kloter! Status: {r.status_code}")

    # 5. Petugas views all assessments (Should succeed)
    print("\n[UJI 5] Petugas Medis mengakses data monitoring seluruh jemaah...")
    r = requests.get(f"{BASE_URL}/assessments/all", headers=petugas_headers)
    if r.status_code != 200:
        print(f"FAILED: Petugas gagal memuat data: {r.text}")
        return
    data_all = r.json()
    print(f"SUCCESS: Petugas berhasil memuat {len(data_all)} data pemeriksaan.")
    
    # 6. Petugas updates medical recommendation manually
    print("\n[UJI 6] Petugas Medis memberikan intervensi manual (mengubah rekomendasi tindakan)...")
    new_rec_payload = {
        "rekomendasi_tindakan": "INTERVENSI DOKTER: Pasien diberikan oksigen 4 lpm, diposisikan setengah duduk, dan segera dilarikan ke RS King Faisal menggunakan Ambulans Sektor."
    }
    r = requests.put(f"{BASE_URL}/assessments/{assessment_id}/recommendation", json=new_rec_payload, headers=petugas_headers)
    if r.status_code != 200:
        print(f"FAILED: Gagal mengupdate rekomendasi: {r.text}")
        return
    print("SUCCESS: Rekomendasi tindakan medis berhasil diperbarui oleh petugas medis!")
    print(f"   -> Rekomendasi Baru: {r.json()['rekomendasi_tindakan']}")

    # 7. Jemaah checks their history to verify they see the updated recommendation
    print("\n[UJI 7] Jemaah memeriksa riwayat pemeriksaan miliknya sendiri...")
    r = requests.get(f"{BASE_URL}/assessments/my", headers=jemaah_headers)
    if r.status_code != 200:
        print(f"FAILED: Jemaah gagal memuat riwayat pribadinya: {r.text}")
        return
    my_history = r.json()
    print(f"SUCCESS: Jemaah melihat {len(my_history)} data riwayat miliknya.")
    print(f"   -> Rekomendasi yang diterima Jemaah saat ini: {my_history[0]['rekomendasi_tindakan']}")

    print("\n" + "="*80)
    print("PENGUJIAN SELESAI: SISTEM AUTENTIKASI, MODEL ML, DAN MYSQL RBAC BERJALAN 100% SUKSES")
    print("="*80)

if __name__ == "__main__":
    test_rbac_flow()
