import React from 'react';
import logo from './logo.svg';
import './App.css';

function App() {
  // Example: Fetch data from backend
  // const [message, setMessage] = React.useState('Loading...');
  // React.useEffect(() => {
  //   // Replace with your actual backend API endpoint
  //   const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:8080'; 
  //   fetch(`${apiUrl}/`)
  //     .then(res => res.json())
  //     .then(data => setMessage(data.message))
  //     .catch(err => {
  //       console.error("Error fetching from backend:", err);
  //       setMessage('Error connecting to backend.');
  //      });
  // }, []);

  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <h1>Welcome to JustEasyLearn</h1>
        {/* <p>{message}</p> */}
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App; 