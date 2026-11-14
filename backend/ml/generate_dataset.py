import pandas as pd
import numpy as np
import random
import os

def generate_simple_dataset(num_samples=1000):
    np.random.seed(42)
    random.seed(42)

    data = []
    
    gejala_list = ['Tidak Ada', 'Pusing', 'Mual', 'Demam', 'Nyeri Dada']
    kondisi_list = ['Sehat', 'Kelelahan', 'Sakit Ringan', 'Sakit Parah']
    riwayat_list = ['Tidak Ada', 'Hipertensi', 'Diabetes', 'Jantung', 'Asma']
    lainnya_list = ['Tidak Ada', 'Dehidrasi', 'Lemas']
    jk_list = ['Laki-laki', 'Perempuan']

    for _ in range(num_samples):
        # Generate dasar
        usia = random.randint(18, 85)
        jenis_kelamin = random.choice(jk_list)
        suhu_tubuh = round(random.uniform(36.0, 37.5), 1)
        
        batuk = 'Tidak'
        sesak_napas = 'Tidak'
        gejala = 'Tidak Ada'
        kondisi = 'Sehat'
        riwayat_penyakit = random.choices(riwayat_list, weights=[60, 15, 10, 10, 5])[0]
        lainnya = 'Tidak Ada'
        
        # Skenario Medis (Prioritas)
        rand_scenario = random.random()
        
        if rand_scenario < 0.2:
            # 20% Risiko Tinggi
            suhu_tubuh = round(random.uniform(38.5, 41.0), 1)
            kondisi = 'Sakit Parah'
            gejala = random.choice(['Nyeri Dada', 'Demam'])
            sesak_napas = random.choice(['Ya', 'Tidak'])
            if gejala == 'Nyeri Dada': sesak_napas = 'Ya'
            lainnya = random.choice(['Lemas', 'Dehidrasi'])
            risiko_label = 'Tinggi'
            
        elif rand_scenario < 0.6:
            # 40% Risiko Sedang
            suhu_tubuh = round(random.uniform(37.5, 38.5), 1)
            kondisi = random.choice(['Kelelahan', 'Sakit Ringan'])
            gejala = random.choice(['Pusing', 'Mual', 'Demam'])
            batuk = random.choice(['Ya', 'Tidak'])
            lainnya = random.choice(['Tidak Ada', 'Dehidrasi'])
            risiko_label = 'Sedang'
            
        else:
            # 40% Risiko Rendah
            kondisi = random.choice(['Sehat', 'Kelelahan'])
            gejala = 'Tidak Ada'
            if riwayat_penyakit != 'Tidak Ada' and usia > 60:
                risiko_label = 'Sedang' # Lansia dgn komorbid minimal sedang
            else:
                risiko_label = 'Rendah'

        data.append({
            'usia': usia,
            'jenis_kelamin': jenis_kelamin,
            'gejala': gejala,
            'kondisi': kondisi,
            'suhu_tubuh': suhu_tubuh,
            'batuk': batuk,
            'sesak_napas': sesak_napas,
            'riwayat_penyakit': riwayat_penyakit,
            'lainnya': lainnya,
            'tingkat_risiko': risiko_label
        })

    df = pd.DataFrame(data)
    
    # Save to CSV
    base_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(base_dir, 'dataset_jemaah_simple.csv')
    df.to_csv(output_path, index=False)
    print(f"Dataset berhasil digenerate: {output_path} ({num_samples} baris)")
    print(df['tingkat_risiko'].value_counts())

if __name__ == "__main__":
    generate_simple_dataset()
