import { motion } from 'framer-motion'

interface HomeProps {
  config: {
    appUrl?: string
    feUrl?: string
    apiUrl?: string
    adminUrl?: string
    environment: string
  }
}

export default function Home({ config }: HomeProps) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 via-white to-secondary-50">
      {/* Header */}
      <header className="fixed top-0 w-full bg-white/80 backdrop-blur-lg border-b border-gray-200 z-50">
        <nav className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="text-2xl font-bold text-primary-600">
              Terruvim
            </div>
            <div className="hidden md:flex space-x-8">
              <a href="#features" className="text-gray-600 hover:text-primary-600 transition">
                Features
              </a>
              <a href="#about" className="text-gray-600 hover:text-primary-600 transition">
                About
              </a>
              <a href="#contact" className="text-gray-600 hover:text-primary-600 transition">
                Contact
              </a>
            </div>
            <div className="flex space-x-4">
              {config.feUrl && (
                <a
                  href={config.feUrl}
                  className="px-4 py-2 text-primary-600 hover:text-primary-700 transition"
                >
                  Sign In
                </a>
              )}
              {config.feUrl && (
                <a
                  href={config.feUrl}
                  className="px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition"
                >
                  Get Started
                </a>
              )}
            </div>
          </div>
        </nav>
      </header>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-6">
        <div className="container mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="text-5xl md:text-7xl font-extrabold text-gray-900 mb-6">
              Modern Cloud
              <span className="block text-transparent bg-clip-text bg-gradient-to-r from-primary-600 to-secondary-600">
                Infrastructure
              </span>
            </h1>
            <p className="text-xl md:text-2xl text-gray-600 mb-12 max-w-3xl mx-auto">
              Build, deploy, and scale your applications with confidence using our
              enterprise-grade infrastructure platform
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              {config.feUrl && (
                <a
                  href={config.feUrl}
                  className="px-8 py-4 bg-primary-600 text-white text-lg rounded-lg hover:bg-primary-700 transition shadow-lg hover:shadow-xl"
                >
                  Start Building
                </a>
              )}
              <a
                href="#features"
                className="px-8 py-4 bg-white text-primary-600 text-lg rounded-lg hover:bg-gray-50 transition border-2 border-primary-600"
              >
                Learn More
              </a>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 px-6 bg-white">
        <div className="container mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
              Why Terruvim?
            </h2>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Everything you need to deploy and manage modern applications
            </p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                title: '⚡ Lightning Fast',
                description: 'Deploy your applications in seconds with our optimized CI/CD pipeline'
              },
              {
                title: '🔒 Secure by Default',
                description: 'Enterprise-grade security with automated compliance and monitoring'
              },
              {
                title: '📈 Auto Scaling',
                description: 'Handle any load with intelligent auto-scaling and load balancing'
              },
              {
                title: '🌍 Global CDN',
                description: 'Deliver content faster with CloudFront and edge locations worldwide'
              },
              {
                title: '💰 Cost Optimized',
                description: 'Pay only for what you use with serverless and containerized services'
              },
              {
                title: '🛠️ Developer Friendly',
                description: 'Simple APIs, comprehensive docs, and excellent developer experience'
              }
            ].map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="p-8 bg-gradient-to-br from-primary-50 to-secondary-50 rounded-2xl hover:shadow-lg transition"
              >
                <h3 className="text-2xl font-bold text-gray-900 mb-4">
                  {feature.title}
                </h3>
                <p className="text-gray-600">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-6 bg-gradient-to-r from-primary-600 to-secondary-600">
        <div className="container mx-auto max-w-4xl text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
          >
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              Ready to Get Started?
            </h2>
            <p className="text-xl text-white/90 mb-8">
              Join thousands of developers building amazing applications on Terruvim
            </p>
            {config.feUrl && (
              <a
                href={config.feUrl}
                className="inline-block px-8 py-4 bg-white text-primary-600 text-lg font-semibold rounded-lg hover:bg-gray-100 transition shadow-lg hover:shadow-xl"
              >
                Create Free Account
              </a>
            )}
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-6 bg-gray-900 text-white">
        <div className="container mx-auto max-w-6xl">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <h3 className="text-2xl font-bold mb-4">Terruvim</h3>
              <p className="text-gray-400">
                Modern cloud infrastructure for modern applications
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Product</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#features" className="hover:text-white transition">Features</a></li>
                <li><a href="#" className="hover:text-white transition">Pricing</a></li>
                <li><a href="#" className="hover:text-white transition">Docs</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Company</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#about" className="hover:text-white transition">About</a></li>
                <li><a href="#" className="hover:text-white transition">Blog</a></li>
                <li><a href="#" className="hover:text-white transition">Careers</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Links</h4>
              <ul className="space-y-2 text-gray-400">
                {config.feUrl && (
                  <li><a href={config.feUrl} className="hover:text-white transition">Dashboard</a></li>
                )}
                {config.apiUrl && (
                  <li><a href={config.apiUrl} className="hover:text-white transition">API</a></li>
                )}
                {config.adminUrl && (
                  <li><a href={config.adminUrl} className="hover:text-white transition">Admin</a></li>
                )}
              </ul>
            </div>
          </div>
          <div className="pt-8 border-t border-gray-800 text-center text-gray-400">
            <p>&copy; 2026 Terruvim. All rights reserved. | Environment: {config.environment}</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
