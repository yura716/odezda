import React, { useState } from 'react';
import axios from 'axios';
import './UploadForm.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

function UploadForm({ onAnalysisComplete, loading, setLoading }) {
  const [photo, setPhoto] = useState(null);
  const [photoPreview, setPhotoPreview] = useState(null);
  const [style, setStyle] = useState('');
  const [error, setError] = useState('');

  const styleOptions = [
    'Casual (повседневный)',
    'Business (деловой)',
    'Sport (спортивный)',
    'Street style (уличный)',
    'Elegant (элегантный)',
    'Romantic (романтичный)',
    'Boho (бохо)',
    'Minimalist (минималистичный)',
    'Vintage (винтаж)',
    'Gothic (готический)',
  ];

  const handlePhotoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 10 * 1024 * 1024) {
        setError('Файл слишком большой. Максимум 10MB.');
        return;
      }
      
      if (!file.type.startsWith('image/')) {
        setError('Пожалуйста, выберите изображение.');
        return;
      }

      setPhoto(file);
      setError('');
      
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhotoPreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!photo) {
      setError('Пожалуйста, загрузите фото.');
      return;
    }
    
    if (!style) {
      setError('Пожалуйста, выберите стиль одежды.');
      return;
    }

    setLoading(true);
    setError('');

    const formData = new FormData();
    formData.append('photo', photo);
    formData.append('style', style);

    try {
      const response = await axios.post(`${API_URL}/api/analyze`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (response.data.success) {
        onAnalysisComplete(response.data.data);
      } else {
        setError('Ошибка при анализе. Попробуйте еще раз.');
        setLoading(false);
      }
    } catch (err) {
      console.error('Error:', err);
      setError(err.response?.data?.detail || 'Ошибка соединения с сервером. Проверьте, что backend запущен.');
      setLoading(false);
    }
  };

  return (
    <div className="upload-form-container">
      <form onSubmit={handleSubmit} className="upload-form">
        <div className="form-section">
          <h2>📸 Загрузите ваше фото</h2>
          
          <div className="photo-upload">
            <input
              type="file"
              id="photo"
              accept="image/*"
              onChange={handlePhotoChange}
              disabled={loading}
            />
            <label htmlFor="photo" className={`photo-label ${photoPreview ? 'has-photo' : ''}`}>
              {photoPreview ? (
                <img src={photoPreview} alt="Preview" className="photo-preview" />
              ) : (
                <div className="upload-placeholder">
                  <span className="upload-icon">📷</span>
                  <span>Нажмите для выбора фото</span>
                  <span className="upload-hint">JPG, PNG (макс. 10MB)</span>
                </div>
              )}
            </label>
          </div>
        </div>

        <div className="form-section">
          <h2>🎨 Выберите желаемый стиль</h2>
          
          <div className="style-selector">
            {styleOptions.map((styleOption) => (
              <label key={styleOption} className="style-option">
                <input
                  type="radio"
                  name="style"
                  value={styleOption}
                  checked={style === styleOption}
                  onChange={(e) => setStyle(e.target.value)}
                  disabled={loading}
                />
                <span>{styleOption}</span>
              </label>
            ))}
          </div>

          <div className="custom-style">
            <p>Или опишите свой стиль:</p>
            <input
              type="text"
              placeholder="Например: минималистичный с яркими акцентами"
              value={!styleOptions.includes(style) ? style : ''}
              onChange={(e) => setStyle(e.target.value)}
              disabled={loading}
              className="custom-style-input"
            />
          </div>
        </div>

        {error && (
          <div className="error-message">
            ⚠️ {error}
          </div>
        )}

        <button 
          type="submit" 
          className="submit-button"
          disabled={loading || !photo || !style}
        >
          {loading ? (
            <>
              <span className="spinner"></span>
              Анализирую и создаю изображение...
            </>
          ) : (
            <>
              ✨ Подобрать одежду и создать визуализацию
            </>
          )}
        </button>
      </form>
    </div>
  );
}

export default UploadForm;


