import React, { useState } from 'react';
import './Results.css';

function Results({ data, onReset }) {
  const { analysis, recommendations, style_tips, generated_image } = data;
  const [imageError, setImageError] = useState(false);

  return (
    <div className="results-container">
      <div className="results-header">
        <h2>✨ Ваши персональные рекомендации</h2>
        <button onClick={onReset} className="reset-button">
          🔄 Новый анализ
        </button>
      </div>

      {/* Сгенерированное изображение */}
      {generated_image && (
        <div className="generated-image-section">
          <h3>🎨 Вы в рекомендованной одежде</h3>
          <div className="generated-image-wrapper">
            {!imageError ? (
              <>
                <img 
                  src={generated_image} 
                  alt="Вы в новой одежде" 
                  className="generated-image"
                  onError={() => setImageError(true)}
                  crossOrigin="anonymous"
                />
                <a 
                  href={generated_image} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="image-direct-link"
                >
                  🔗 Открыть в полном размере
                </a>
              </>
            ) : (
              <div className="image-error">
                <p>⚠️ Изображение не загрузилось в браузере</p>
                <p className="error-hint">Возможно, Imgur заблокирован вашим провайдером</p>
                <a 
                  href={generated_image} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="direct-link-button"
                >
                  📸 Открыть изображение напрямую
                </a>
              </div>
            )}
            <p className="image-note">
              ✨ Это AI-визуализация того, как вы будете выглядеть в рекомендованной одежде
            </p>
          </div>
        </div>
      )}

      {/* Анализ внешности */}
      {analysis && (
        <div className="analysis-section">
          <h3>👤 Анализ внешности</h3>
          <p>{analysis}</p>
        </div>
      )}

      {/* Советы по стилю */}
      {style_tips && style_tips.length > 0 && (
        <div className="tips-section">
          <h3>💡 Советы по стилю</h3>
          <ul className="tips-list">
            {style_tips.map((tip, index) => (
              <li key={index}>{tip}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Рекомендации одежды */}
      {recommendations && recommendations.length > 0 && (
        <div className="recommendations-section">
          <h3>🛍️ Рекомендуемая одежда</h3>
          <div className="recommendations-grid">
            {recommendations.map((rec, index) => (
              <div key={index} className="recommendation-card">
                <div className="card-header">
                  <span className="item-number">{index + 1}</span>
                  <h4>{rec.item}</h4>
                </div>
                
                <p className="description">{rec.description}</p>
                
                <div className="why-section">
                  <strong>Почему это подходит:</strong>
                  <p>{rec.why}</p>
                </div>

                {rec.shop_links && rec.shop_links.length > 0 && (
                  <div className="shop-links">
                    <strong>🔗 Где купить:</strong>
                    <div className="links-grid">
                      {rec.shop_links.map((link, idx) => (
                        <a
                          key={idx}
                          href={link.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="shop-link"
                        >
                          {link.name}
                        </a>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      <button onClick={onReset} className="bottom-reset-button">
        🔄 Подобрать другой стиль
      </button>
    </div>
  );
}

export default Results;


