import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Home from './pages/Home'

// Environment variables
const config = {
  appUrl: import.meta.env.VITE_APP_URL,
  feUrl: import.meta.env.VITE_FE_URL,
  apiUrl: import.meta.env.VITE_API_URL,
  adminUrl: import.meta.env.VITE_ADMIN_URL,
  environment: import.meta.env.VITE_ENVIRONMENT || 'dev'
}

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home config={config} />} />
      </Routes>
    </Router>
  )
}

export default App
