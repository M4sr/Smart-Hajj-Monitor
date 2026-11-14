import os
import sys
import pandas as pd
import numpy as np
import joblib
from imblearn.over_sampling import SMOTE
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix
from sklearn.preprocessing import StandardScaler, OneHotEncoder, LabelEncoder
from sklearn.compose import ColumnTransformer

# --- 1. SETUP PATH & LOAD DATA ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)
DATA_PATH = os.path.join(os.path.dirname(os.path.dirname(BASE_DIR)), 'dataset_jemaah_simple.csv')

if not os.path.exists(DATA_PATH):
    raise FileNotFoundError(f"Dataset tidak ditemukan di: {DATA_PATH}")

df = pd.read_csv(DATA_PATH)
print("=== INFO DATASET SKRIPSI ASLI ===")
print(f"Bentuk Awal Dataset: {df.shape[0]} baris, {df.shape[1]} kolom\n")

# --- 2. DETEKSI STRUKTUR DATASET & PEMBERSIHAN DATA ---
# Deteksi apakah menggunakan dataset simple atau dataset skripsi asli berdasarkan nama kolom target
if 'tingkat_risiko' in df.columns:
    print("[INFO] Mendeteksi Dataset Jemaah Simple (dataset_jemaah_simple.csv)")
    target_col = 'tingkat_risiko'
    
    # Dataset simple tidak memerlukan pembuangan kolom khusus skripsi
    df_clean = df.copy()
    
    # Bersihkan spasi berlebih pada kolom kategorikal dan target
    for col in df_clean.select_dtypes(include=['object']).columns:
        df_clean[col] = df_clean[col].astype(str).str.strip()
        
    df_clean = df_clean[df_clean[target_col].isin(['Rendah', 'Sedang', 'Tinggi'])]
    
    X = df_clean.drop(columns=[target_col])
    y = df_clean[target_col]
    
    numerical_cols = ['usia', 'suhu_tubuh']
    categorical_cols = ['jenis_kelamin', 'gejala', 'kondisi', 'batuk', 'sesak_napas', 'riwayat_penyakit', 'lainnya']
else:
    # Menggunakan target skripsi ('Tingkat Risiko')
    target_col = 'Tingkat Risiko'
    if target_col not in df.columns:
        # Jika ada variasi penulisan case lain
        matching_cols = [col for col in df.columns if col.lower() == 'tingkat risiko']
        if matching_cols:
            target_col = matching_cols[0]
        else:
            raise KeyError(f"Kolom target 'Tingkat Risiko' atau 'tingkat_risiko' tidak ditemukan. Kolom yang tersedia: {list(df.columns)}")

    print(f"[INFO] Mendeteksi Dataset Skripsi (Target: {target_col})")
    
    # Hapus kolom yang tidak relevan untuk training ML (Nama, Rekomendasi, dan kolom kosong Unnamed)
    cols_to_drop = ['Nama', 'Rekomendasi Tindakan']
    unnamed_cols = [col for col in df.columns if 'Unnamed' in col]
    cols_to_drop.extend(unnamed_cols)
    
    df_clean = df.drop(columns=cols_to_drop, errors='ignore')
    
    # Bersihkan spasi berlebih pada kolom kategorikal dan target
    for col in df_clean.select_dtypes(include=['object']).columns:
        df_clean[col] = df_clean[col].astype(str).str.strip()
        
    df_clean = df_clean[df_clean[target_col].isin(['Rendah', 'Sedang', 'Tinggi'])]
    
    X = df_clean.drop(columns=[target_col])
    y = df_clean[target_col]
    
    # Sesuaikan kolom numerik & kategorikal untuk format dataset skripsi
    numerical_cols = [col for col in [
        'Usia', 'Suhu Tubuh (C)', 'Tekanan Darah (Sistolik)', 
        'Tekanan Darah (Diastolik)', 'Detak Jantung (bpm)', 'Laju Pernapasan (kali/menit)'
    ] if col in X.columns]
    
    categorical_cols = [col for col in ['Jenis Kelamin', 'Penyakit Komorbid', 'Gejala Utama'] if col in X.columns]

print("Fitur yang digunakan:")
for i, col in enumerate(X.columns, 1):
    print(f"{i}. {col}")
print(f"\nTarget Klasifikasi: {target_col}")
print(y.value_counts())
print("==================================\n")

# --- 3. PREPROCESSING PIPELINE ---
# Buat transformator kolom (Standardisasi angka, One-Hot Encoding teks)
preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numerical_cols),
        ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_cols)
    ]
)

# Encode Target (Rendah -> 0, Sedang -> 1, Tinggi -> 2)
le = LabelEncoder()
y_encoded = le.fit_transform(y)

# --- 4. TRAIN-TEST SPLIT (PENTING: Split DULU sebelum SMOTE!) ---
# Menggunakan 80% data latih dan 20% data uji
X_train, X_test, y_train, y_test = train_test_split(
    X, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
)

# Transformasikan fitur latih dan uji menggunakan pipeline
X_train_processed = preprocessor.fit_transform(X_train)
X_test_processed = preprocessor.transform(X_test)

# --- 5. OVERSAMPLING MENGGUNAKAN SMOTE (Hanya pada data latih!) ---
# SMOTE dijalankan hanya pada X_train untuk mencegah kebocoran data (Data Leakage)
smote = SMOTE(random_state=42)
X_train_res, y_train_res = smote.fit_resample(X_train_processed, y_train)

# --- 6. MODEL TRAINING (Random Forest) ---
# Menggunakan hyperparameter terkontrol agar tidak overfit
rf_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=6,          # Dibatasi agar model melakukan generalisasi dengan baik (tidak menghafal)
    min_samples_split=5,
    random_state=42,
    class_weight='balanced'
)
rf_model.fit(X_train_res, y_train_res)

# --- 7. EVALUASI MODEL ---
# Prediksi data uji (data yang belum pernah dilihat model selama latihan)
y_pred = rf_model.predict(X_test_processed)

accuracy = accuracy_score(y_test, y_pred)
conf_matrix = confusion_matrix(y_test, y_pred)

print("============================================================")
# Laporan Klasifikasi Riil
print(f"AKURASI MODEL PADA DATA UJI: {accuracy * 100:.2f}%")
print("============================================================")
print("\nClassification Report (Data Uji):")
print(classification_report(y_test, y_pred, target_names=le.classes_))

print("\nConfusion Matrix:")
print(pd.DataFrame(conf_matrix, index=le.classes_, columns=le.classes_))

# --- 8. VALIDASI SILANG (CROSS-VALIDATION) ---
# Membuktikan stabilitas model menggunakan K-Fold Cross Validation (K=5)
# Kami gabungkan seluruh data latih terproses untuk dinilai stabilitasnya
cv_scores = cross_val_score(rf_model, X_train_processed, y_train, cv=5, scoring='accuracy')
print("\n============================================================")
print("VALIDASI SILANG (5-FOLD CROSS VALIDATION)")
print("==================================================")
print(f"Skor Akurasi tiap fold: {cv_scores}")
print(f"Rata-rata Akurasi CV  : {cv_scores.mean() * 100:.2f}%")
print(f"Standar Deviasi CV    : {cv_scores.std() * 100:.2f}%")
print("============================================================\n")

print("Catatan Skripsi:")
print("1. SMOTE dilakukan hanya pada X_train untuk menghindari data leakage.")
print("2. Akurasi di atas adalah akurasi riil (bukan artifisial 100% karena bocor).")
print("3. Model siap digunakan secara akademis.")

# --- 9. OPSI CETAK LAPORAN PDF ---
try:
    print("\n============================================================")
    cetak = input("Apakah Anda ingin mencetak hasil laporan evaluasi model ke dalam format PDF? (y/n): ").strip().lower()
    if cetak == 'y':
        from report_generator import generate_pdf_report
        # Konversi confusion matrix ke DataFrame dengan label index & column untuk mempermudah visualisasi di PDF
        df_conf = pd.DataFrame(conf_matrix, index=le.classes_, columns=le.classes_)
        # Dapatkan classification report dalam format dict
        report_dict = classification_report(y_test, y_pred, target_names=le.classes_, output_dict=True)
        
        output_filename = os.path.join(BASE_DIR, "laporan_evaluasi_model.pdf")
        generate_pdf_report(
            accuracy=accuracy,
            classification_report_dict=report_dict,
            conf_matrix=df_conf,
            cv_scores=cv_scores,
            dataset_name=DATA_PATH,
            output_path=output_filename
        )
except Exception as e:
    print(f"[ERROR] Gagal mencetak laporan PDF: {e}")

