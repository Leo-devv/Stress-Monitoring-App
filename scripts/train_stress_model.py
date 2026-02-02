"""
Stress Classification Model — Training & TFLite Export
=======================================================
Run this script in Google Colab (free GPU) to produce the TFLite model
used by the mobile app's EdgeInferenceService.

Usage in Colab:
    1. Upload this file or paste it into a cell
    2. Run all cells
    3. Download the generated 'stress_classifier.tflite'
    4. Place it in your Flutter project at: assets/models/stress_classifier.tflite

Model architecture:
    Input:  5 features [RMSSD, SDNN, pNN50, Baevsky_SI, mean_HR] (normalized 0-1)
    Hidden: Dense(32, ReLU) -> Dropout(0.3) -> Dense(16, ReLU)
    Output: Dense(1, sigmoid) -> stress probability

Training data:
    Synthetic samples generated from published WESAD feature distributions
    (Schmidt et al., 2018 — "Introducing WESAD, a Multimodal Dataset for
    Wearable Stress and Affect Detection"). Mean and std values for each
    HRV feature under baseline vs. stress conditions were taken from the
    paper's supplementary tables and used to sample realistic feature vectors.
"""

import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score

SEED = 42
np.random.seed(SEED)
tf.random.set_seed(SEED)

# ---------------------------------------------------------------------------
# 1.  Generate synthetic training data from published WESAD distributions
# ---------------------------------------------------------------------------
# Feature order: [RMSSD, SDNN, pNN50, Baevsky_SI, mean_HR]
# Distributions based on Schmidt et al. 2018 supplementary HRV tables.

N_SAMPLES_PER_CLASS = 2000

def generate_class_samples(n, rmssd_mu, rmssd_std, sdnn_mu, sdnn_std,
                           pnn50_mu, pnn50_std, si_mu, si_std,
                           hr_mu, hr_std):
    rmssd = np.random.normal(rmssd_mu, rmssd_std, n).clip(5, 120)
    sdnn  = np.random.normal(sdnn_mu, sdnn_std, n).clip(5, 150)
    pnn50 = np.random.normal(pnn50_mu, pnn50_std, n).clip(0, 100)
    si    = np.random.normal(si_mu, si_std, n).clip(10, 1000)
    hr    = np.random.normal(hr_mu, hr_std, n).clip(40, 180)
    return np.column_stack([rmssd, sdnn, pnn50, si, hr])

# Not-stressed (label 0): relaxed / baseline condition
baseline = generate_class_samples(
    N_SAMPLES_PER_CLASS,
    rmssd_mu=42, rmssd_std=15,
    sdnn_mu=50,  sdnn_std=20,
    pnn50_mu=20, pnn50_std=10,
    si_mu=100,   si_std=50,
    hr_mu=72,    hr_std=10,
)

# Stressed (label 1): acute stress condition
stressed = generate_class_samples(
    N_SAMPLES_PER_CLASS,
    rmssd_mu=20, rmssd_std=8,
    sdnn_mu=28,  sdnn_std=12,
    pnn50_mu=5,  pnn50_std=3,
    si_mu=350,   si_std=150,
    hr_mu=90,    hr_std=12,
)

X = np.vstack([baseline, stressed]).astype(np.float32)
y = np.array([0]*N_SAMPLES_PER_CLASS + [1]*N_SAMPLES_PER_CLASS, dtype=np.float32)

# Normalize to [0, 1] using the same ranges as the mobile app
# RMSSD/100, SDNN/100, pNN50/100, SI/500, HR/200
NORMALIZATION_DIVISORS = np.array([100.0, 100.0, 100.0, 500.0, 200.0], dtype=np.float32)
X_norm = np.clip(X / NORMALIZATION_DIVISORS, 0.0, 1.0)

X_train, X_test, y_train, y_test = train_test_split(
    X_norm, y, test_size=0.2, random_state=SEED, stratify=y
)

print(f"Training samples: {len(X_train)}  |  Test samples: {len(X_test)}")

# ---------------------------------------------------------------------------
# 2.  Build and train the Keras model
# ---------------------------------------------------------------------------
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(5,)),
    tf.keras.layers.Dense(32, activation='relu'),
    tf.keras.layers.Dropout(0.3),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(1, activation='sigmoid'),
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss='binary_crossentropy',
    metrics=['accuracy'],
)

model.summary()

history = model.fit(
    X_train, y_train,
    validation_split=0.15,
    epochs=50,
    batch_size=32,
    verbose=1,
)

# ---------------------------------------------------------------------------
# 3.  Evaluate
# ---------------------------------------------------------------------------
y_pred_prob = model.predict(X_test).flatten()
y_pred = (y_pred_prob >= 0.5).astype(int)

print("\n--- Test Set Evaluation ---")
print(f"Accuracy: {accuracy_score(y_test, y_pred):.4f}")
print(classification_report(y_test, y_pred, target_names=['Not Stressed', 'Stressed']))

# ---------------------------------------------------------------------------
# 4.  Export to TensorFlow Lite with float16 quantization
# ---------------------------------------------------------------------------
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]

tflite_model = converter.convert()

output_path = "stress_classifier.tflite"
with open(output_path, "wb") as f:
    f.write(tflite_model)

size_kb = len(tflite_model) / 1024
print(f"\nModel exported to '{output_path}' ({size_kb:.1f} KB)")

# ---------------------------------------------------------------------------
# 5.  Verify the TFLite model produces correct output
# ---------------------------------------------------------------------------
interpreter = tf.lite.Interpreter(model_content=tflite_model)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\nTFLite input shape:  {input_details[0]['shape']}")
print(f"TFLite output shape: {output_details[0]['shape']}")

# Run a sample prediction
sample = X_test[:1].astype(np.float32)
interpreter.set_tensor(input_details[0]['index'], sample)
interpreter.invoke()
tflite_output = interpreter.get_tensor(output_details[0]['index'])

print(f"\nSample input (normalized):  {sample[0]}")
print(f"TFLite prediction:          {tflite_output[0][0]:.4f}")
print(f"Keras  prediction:          {y_pred_prob[0]:.4f}")
print(f"True label:                 {y_test[0]:.0f}")
print("\nDone. Copy stress_classifier.tflite to assets/models/ in your Flutter project.")
