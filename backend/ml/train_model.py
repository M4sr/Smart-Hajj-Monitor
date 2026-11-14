import os
import pandas as pd
import joblib
import json
from imblearn.over_sampling import SMOTE
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import StandardScaler, OneHotEncoder, LabelEncoder
from sklearn.compose import ColumnTransformer

# --- 1. SETUP PATH ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, 'dataset_jemaah_simple.csv')
MODEL_DIR = os.path.join(os.path.dirname(BASE_DIR), 'model')
os.makedirs(MODEL_DIR, exist_ok=True)

# --- 2. LOAD DATA ---
df = pd.read_csv(DATA_PATH)
print(f"Dataset shape: {df.shape}")

# Pisahkan fitur dan target
X = df.drop('tingkat_risiko', axis=1)
y = df['tingkat_risiko']

# --- 3. PREPROCESSING ---
# Define columns
categorical_cols = ['jenis_kelamin', 'gejala', 'kondisi', 'batuk', 'sesak_napas', 'riwayat_penyakit', 'lainnya']
numeric_cols = ['usia', 'suhu_tubuh']

# Build ColumnTransformer
preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numeric_cols),
        ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_cols)
    ])

# Fit transform X
X_processed = preprocessor.fit_transform(X)

# Encode label
le = LabelEncoder()
y_encoded = le.fit_transform(y)

# Split data first (untouched test set)
X_train, X_test, y_train, y_test = train_test_split(X_processed, y_encoded, test_size=0.2, random_state=42)

# --- 4. SMOTE (Handling Imbalance) ---
# Terapkan SMOTE HANYA pada data latih (training set)
smote = SMOTE(random_state=42)
X_train_res, y_train_res = smote.fit_resample(X_train, y_train)

# --- 5. TRAINING ---
rf_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=10,
    random_state=42,
    class_weight='balanced'
)
rf_model.fit(X_train_res, y_train_res)
print("Model berhasil dilatih!")

# --- 6. EVALUASI ---
y_pred = rf_model.predict(X_test)
print("\n============================================================")
print("HASIL EVALUASI MODEL")
print("============================================================")
print(f"Akurasi: {accuracy_score(y_test, y_pred):.4f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=le.classes_))

# Save artifacts
joblib.dump(rf_model, os.path.join(MODEL_DIR, 'rf_model.pkl'))
joblib.dump(preprocessor, os.path.join(MODEL_DIR, 'preprocessor.pkl'))
joblib.dump(le, os.path.join(MODEL_DIR, 'label_encoder.pkl'))

# Save feature layout for API input reference
feature_info = {
    "numeric": numeric_cols,
    "categorical": categorical_cols
}
with open(os.path.join(MODEL_DIR, 'feature_info.json'), 'w') as f:
    json.dump(feature_info, f)

print(f"\nModel, Preprocessor, dan LabelEncoder tersimpan di {MODEL_DIR}")
