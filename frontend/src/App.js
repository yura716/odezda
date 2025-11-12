import React, { useState } from 'react';
import './App.css';
import UploadForm from './components/UploadForm';
import Results from './components/Results';

function App() {
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleAnalysisComplete = (data) => {
    setResults(data);
    setLoading(false);
  };

  const handleReset = () => {
    setResults(null);
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>👗 Odezda</h1>
        <p>AI-стилист для подбора идеальной одежды</p>
      </header>

      <main className="App-main">
        {!results ? (
          <UploadForm 
            onAnalysisComplete={handleAnalysisComplete}
            loading={loading}
            setLoading={setLoading}
          />
        ) : (
          <Results data={results} onReset={handleReset} />
        )}
      </main>

      <footer className="App-footer">
        <p>© 2025 Odezda AI. Создано с ❤️ и искусственным интеллектом</p>
      </footer>
    </div>
  );
}

export default App;


