-- Crear base de datos
CREATE DATABASE IF NOT EXISTS marketplace CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE marketplace;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role ENUM('student', 'admin', 'guest') DEFAULT 'student',
    google_id VARCHAR(255) NULL,
    avatar_url TEXT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_google_id (google_id)
);

-- Tabla de productos/servicios
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category ENUM('academic', 'technology', 'books', 'services', 'other') NOT NULL,
    condition_type ENUM('new', 'used', 'excellent') DEFAULT 'used',
    images JSON NULL,
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_category (category),
    INDEX idx_user_id (user_id),
    INDEX idx_available (is_available)
);

-- Tabla de categorías
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    icon VARCHAR(50) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar categorías iniciales
INSERT INTO categories (name, description, icon) VALUES 
('academic', 'Materiales académicos y educativos', 'school'),
('technology', 'Dispositivos y accesorios tecnológicos', 'computer'),
('books', 'Libros de texto y literatura', 'menu_book'),
('services', 'Servicios ofrecidos por estudiantes', 'build'),
('other', 'Otros productos y servicios', 'category')
ON DUPLICATE KEY UPDATE description=VALUES(description);

-- Insertar usuario demo (password: demo123)
INSERT INTO users (email, password, name, role, email_verified) VALUES 
('demo@uct.cl', '$2a$10$8ZJQJRGOp5GE9q.PLUYQUeIwJvMxXqYdR7lJpOHYzW3z2IzZxrqfu', 'Usuario Demo', 'student', TRUE),
('admin@uct.cl', '$2a$10$8ZJQJRGOp5GE9q.PLUYQUeIwJvMxXqYdR7lJpOHYzW3z2IzZxrqfu', 'Administrador', 'admin', TRUE)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Insertar productos demo
INSERT INTO products (user_id, title, description, price, category, condition_type) VALUES 
(1, 'Calculadora Científica Casio', 'Calculadora científica en excelente estado, ideal para ingeniería', 25000.00, 'academic', 'used'),
(1, 'Libro Cálculo Stewart 8va Edición', 'Libro de cálculo en muy buen estado, con algunos subrayados', 45000.00, 'books', 'used'),
(1, 'Laptop HP Pavilion', 'Laptop para estudiantes, 8GB RAM, 256GB SSD, ideal para programación', 450000.00, 'technology', 'used')
ON DUPLICATE KEY UPDATE title=VALUES(title);
