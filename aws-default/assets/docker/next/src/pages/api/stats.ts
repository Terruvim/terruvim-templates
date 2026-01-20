import { NextApiRequest, NextApiResponse } from 'next';

// Имитация данных системной статистики
const generateSystemStats = () => ({
  uptime: Math.floor(Math.random() * 86400), // случайное время работы в секундах
  memory: {
    used: Math.floor(Math.random() * 2048), // MB
    total: 4096,
    free: 4096 - Math.floor(Math.random() * 2048)
  },
  cpu: {
    usage: Math.floor(Math.random() * 100), // проценты
    cores: 4,
    loadAverage: [
      (Math.random() * 2).toFixed(2),
      (Math.random() * 2).toFixed(2),
      (Math.random() * 2).toFixed(2)
    ]
  },
  services: [
    {
      name: 'web-server',
      status: Math.random() > 0.1 ? 'running' : 'stopped',
      port: 3000,
      pid: Math.floor(Math.random() * 10000) + 1000
    },
    {
      name: 'database',
      status: Math.random() > 0.05 ? 'running' : 'stopped',
      port: 5432,
      pid: Math.floor(Math.random() * 10000) + 1000
    },
    {
      name: 'cache',
      status: Math.random() > 0.1 ? 'running' : 'stopped',
      port: 6379,
      pid: Math.floor(Math.random() * 10000) + 1000
    }
  ],
  requests: {
    total: Math.floor(Math.random() * 100000),
    perSecond: Math.floor(Math.random() * 100),
    errors: Math.floor(Math.random() * 10),
    avgResponseTime: Math.floor(Math.random() * 200) + 50
  }
});

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'GET') {
    const stats = generateSystemStats();
    
    res.status(200).json({
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
      stats
    });
  } else {
    res.setHeader('Allow', ['GET']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
