-- DROP DATABASE despegar;
CREATE DATABASE despegar;
USE despegar;
-- SHOW TABLES;


-- ------------------------------------------------------- Tables' Creation Scripts ----------------------------------------------------------------------

DROP TABLE IF EXISTS ubicacion;
CREATE TABLE ubicacion(
	id_location INT NOT NULL AUTO_INCREMENT,
    city_name VARCHAR(30) NOT NULL,
    city_zipcode INT NOT NULL,
    state VARCHAR(30) NOT NULL,
    country VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_location),
    UNIQUE (city_name)
);


DROP TABLE IF EXISTS departamentos;           
CREATE TABLE departamentos(
	id_department INT NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(30)NOT NULL,
    department_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (id_department)
);


DROP TABLE  IF EXISTS rangos;
CREATE TABLE rangos(
	id_rank INT NOT NULL AUTO_INCREMENT,
    rank_name_hierarchy VARCHAR(30) NOT NULL,
    salary_floor DECIMAL NOT NULL,
    salary_ceiling DECIMAL NOT NULL,
    PRIMARY KEY (id_rank)
);

DROP TABLE  IF EXISTS puestos;   
CREATE TABLE puestos(
	id_position INT NOT NULL AUTO_INCREMENT,
    position_name VARCHAR(30) NOT NULL,
    id_rank INT NOT NULL,
    id_department INT NOT NULL,
    PRIMARY KEY (id_position),
    FOREIGN KEY (id_rank) REFERENCES rangos(id_rank),
    FOREIGN KEY (id_department) REFERENCES departamentos(id_department)
);


DROP TABLE  IF EXISTS empleados;
CREATE TABLE empleados(
	id_employee INT NOT NULL AUTO_INCREMENT,
    employee_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(50) NOT NULL,
    address VARCHAR(150) NOT NULL,
    rfc_employee VARCHAR(50) NOT NULL UNIQUE,
    salary DECIMAL NOT NULL,
    employee_bank_name VARCHAR(70) NOT NULL,
    employee_bank_account VARCHAR(12) NOT NULL,
    hiring_date DATE NOT NULL,
    id_location INT,
    id_position INT,
    PRIMARY KEY (id_employee),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location),
    FOREIGN KEY (id_position) REFERENCES puestos(id_position),
    UNIQUE (rfc_employee)
);

    
DROP TABLE  IF EXISTS categoria_actividades;
CREATE TABLE categoria_actividades(
	id_category INT NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_category)
);        


DROP TABLE  IF EXISTS proveedores_experiencias;
CREATE TABLE proveedores_experiencias(
	id_supplier INT NOT NULL AUTO_INCREMENT,
    company_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(50) NOT NULL,
    main_contact_name VARCHAR(150) NOT NULL,
    payment_method VARCHAR(70) NOT NULL,
    bank_name VARCHAR(150) NOT NULL,
    bank_account VARCHAR(12) NOT NULL,
    supplier_rfc VARCHAR(50) NOT NULL,
    id_location INT NOT NULL,
	PRIMARY KEY (id_supplier),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location),    
    UNIQUE (supplier_rfc)
);        


DROP TABLE  IF EXISTS experiencias_tours;
CREATE TABLE experiencias_tours(
	id_experience INT NOT NULL AUTO_INCREMENT,
    experience_name VARCHAR(150) NOT NULL,
    id_category INT NOT NULL,
    experience_description VARCHAR(255) NOT NULL,
    duration INT NOT NULL,
    requirements_restrictions VARCHAR(255) NOT NULL,
    price_per_person DECIMAL NOT NULL,
    payment_agreement_percent DECIMAL NOT NULL,
    id_location INT NOT NULL,
    id_supplier INT NOT NULL,
    PRIMARY KEY (id_experience),
    FOREIGN KEY (id_category) REFERENCES categoria_actividades(id_category),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location),
    FOREIGN KEY (id_supplier) REFERENCES proveedores_experiencias(id_supplier)
);


DROP TABLE  IF EXISTS clientes;
CREATE TABLE clientes(
	id_customer INT NOT NULL AUTO_INCREMENT,
    customer_name VARCHAR(150) NOT NULL,
    email VARCHAR(50) NOT NULL,
    phone VARCHAR(70) NOT NULL,
    rfc_customer VARCHAR(50) NOT NULL UNIQUE,
    id_location INT NOT NULL,
    PRIMARY KEY (id_customer),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location)
);


DROP TABLE  IF EXISTS ventas;
CREATE TABLE ventas(
	id_sale_transaction INT NOT NULL AUTO_INCREMENT,
    id_customer INT NOT NULL,
    id_experience INT NOT NULL,
    sale_date DATE NOT NULL,
    experience_date DATE NOT NULL,
    group_size INT NOT NULL,
    amount_total DECIMAL, 
    id_employee_sale INT NOT NULL,
    notes VARCHAR(255),
    PRIMARY KEY (id_sale_transaction),
    FOREIGN KEY (id_customer) REFERENCES clientes(id_customer),
    FOREIGN KEY (id_experience) REFERENCES experiencias_tours(id_experience),
    FOREIGN KEY (id_employee_sale) REFERENCES empleados(id_employee)
);


DROP TABLE  IF EXISTS pago_proveedores;
CREATE TABLE pago_proveedores(
	id_payment_transaction INT NOT NULL AUTO_INCREMENT,
    id_sale_transaction INT NOT NULL,
    sale_trx_value DECIMAL(10,2), -- value added via trigger
    commission_agreed DECIMAL(10,2), -- value added via trigger
    total_payment DECIMAL(10,2), -- value added via trigger
    PRIMARY KEY (id_payment_transaction),
    FOREIGN KEY (id_sale_transaction) REFERENCES ventas(id_sale_transaction)
);
 
 
DROP TABLE  IF EXISTS FEEDBACK;
CREATE TABLE feedback(
	id_feedback INT NOT NULL AUTO_INCREMENT,
    id_customer INT NOT NULL,
    id_experience INT NOT NULL, 
    feedback_received VARCHAR(300) NOT NULL,
    feedback_status INT NOT NULL,
    resolution VARCHAR(300),
    PRIMARY KEY (id_feedback),
    FOREIGN KEY (id_customer) REFERENCES clientes(id_customer),
    FOREIGN KEY (id_experience) REFERENCES experiencias_tours(id_experience)
);



-- ------------------------------------------------------- Trigger Scripts ----------------------------------------------------------------------

  -- ---------  TRIGGER PRE- VENTAS --------------------------
DROP TRIGGER IF EXISTS tr_insertar_ventas_totales;
DELIMITER //
CREATE TRIGGER tr_insertar_ventas_totales
BEFORE INSERT ON ventas
FOR EACH ROW
BEGIN
   
    DECLARE exp_price_per_person DECIMAL (10,2);
    
    SELECT price_per_person 
    INTO exp_price_per_person
    FROM experiencias_tours AS e
    WHERE e.id_experience = NEW.id_experience;
    
    SET NEW.amount_total = NEW.group_size * exp_price_per_person;
    
END;
//

-- --------- TRIGGER PRE- PAGO A PROVEEDORES ------------------

DROP TRIGGER IF EXISTS tr_detalles_pago_proveedores
DELIMITER //
CREATE TRIGGER tr_detalles_pago_proveedores
BEFORE INSERT ON pago_proveedores
FOR EACH ROW
BEGIN
   
    DECLARE total_sale DECIMAL (10,2);
	DECLARE despegar_commission_base DECIMAL(10,2);
    DECLARE total_payment DECIMAL(10,2);
    
    SELECT amount_total
    INTO total_sale
    FROM ventas AS v
    WHERE v.id_sale_transaction = NEW.id_sale_transaction;
    
    SET NEW.sale_trx_value = total_sale;

    SELECT payment_agreement_percent
	INTO despegar_commission_base
	FROM experiencias_tours AS ex
		INNER JOIN ventas AS v ON (v.id_experience = ex.id_experience)
    WHERE v.id_sale_transaction = NEW.id_sale_transaction;
    
    SET NEW.commission_agreed = despegar_commission_base;
    
    SET total_payment = total_sale - ((despegar_commission_base/100) * total_sale);
    
    SET NEW.total_payment = total_payment;
    
END;
//


-- ------------------------------------------------------- Data Insert Scripts ----------------------------------------------------------------------

INSERT INTO ubicacion (id_location,city_name,city_zipcode,state,country)
VALUES (null,'cdmx', 03023, 'ciudad de méxico', 'méxico'),
	   (null,'villahermosa', 86029, 'tabasco', 'méxico' ),
	   (null, 'Guadalajara', 44100, 'Jalisco', 'México'),
	   (null, 'Monterrey', 64000, 'Nuevo León', 'México'),
	   (null, 'Puebla', 72000, 'Puebla', 'México'),
	   (null, 'Tijuana', 22000, 'Baja California', 'México'),
	   (null, 'León', 37000, 'Guanajuato', 'México'),
	   (null, 'Juárez', 32000, 'Chihuahua', 'México'),
	   (null, 'Mérida', 97000, 'Yucatán', 'México'),
	   (null, 'Mexicali', 21000, 'Baja California', 'México'),
	   (null, 'Acapulco', 39300, 'Guerrero', 'México'),
	   (null, 'Cancún', 77500, 'Quintana Roo', 'México'),
	   (null, 'Chihuahua', 31000, 'Chihuahua', 'México'),
	   (null, 'Veracruz', 91700, 'Veracruz', 'México'),
	   (null, 'Cuernavaca', 62000, 'Morelos', 'México'),
	   (null, 'Saltillo', 25000, 'Coahuila', 'México'),
	   (null, 'Toluca', 50000, 'Estado de México', 'México'),
	   (null, 'Hermosillo', 83000, 'Sonora', 'México'),
	   (null, 'Xalapa', 91000, 'Veracruz', 'México'),
	   (null, 'Tuxtla Gutiérrez', 29000, 'Chiapas', 'México'),
	   (null, 'Culiacán', 80000, 'Sinaloa', 'México'),
	   (null, 'Campeche', 24000, 'Campeche', 'México'),
	   (null, 'Morelia', 58000, 'Michoacán', 'México'),
	   (null, 'Colima', 28000, 'Colima', 'México'),
	   (null, 'Durango', 34000, 'Durango', 'México'),
	   (null, 'San Luis Potosí', 78000, 'San Luis Potosí', 'México'),
	   (null, 'Tapachula', 30700, 'Chiapas', 'México'),
	   (null, 'Oaxaca', 68000, 'Oaxaca', 'México'),
	   (null, 'Tepic', 63000, 'Nayarit', 'México'),
	   (null, 'Querétaro', 76000, 'Querétaro', 'México');
           
           
INSERT INTO departamentos (id_department, department_name, department_description)
VALUES (null, 'Ventas', 'Encargado de gestionar y promover la venta de tours con socios operadores y clientes'),
	   (null, 'Operaciones', 'Equipo a cargo de la correcta ejecución y supervisión de las experiencias y tours con clientes'),
	   (null, 'Administración', 'Departamento encargado de las gestiones administrativas de la empresa ej. cobros, pagos, contrataciones etc'),
	   (null, 'Recursos Humanos', 'Equipo a cargo de la supervisión de la cultura laboral, métricas de desempeño y clima general en favor del personal'),
	   (null, 'Sistemas y TI', 'Equipo nuevo a cargo de la implementación del proyecto de digitalización y normalización tecnológica de la empresa'),
	   (null, 'Equipo Ejecutivo', 'Equipo de alta dirección, análisis de métricas y toma de decisiones estratégicas');
           
           
INSERT INTO rangos (id_rank,rank_name_hierarchy, salary_floor, salary_ceiling)
VALUES  (null, 'asistente administrativo', 6000, 10000),
		(null,'analista', 8000,12000),
		(null, 'técnico de soporte', 7000, 11000),
		(null, 'especialista de area', 9000, 15000),
		(null, 'coordinador de proyectos', 10000, 16000),
		(null, 'supervisor', 11000, 17000),
		(null, 'gerente de área', 12000, 20000),
		(null, 'director de area admin', 15000, 25000),
		(null, 'director de area técnica', 18000, 30000),
		(null, 'director general', 25000, 40000);
        
INSERT INTO puestos (id_position, position_name, id_rank, id_department)
VALUES  (null, 'directora general', 10, 6),
		(null, 'asistente administrativo', 1, 3), 
		(null, 'asistente de ventas', 1, 1),
		(null, 'asistente ejecutivo A', 1, 6),
		(null, 'asistente ejecutivo B', 1, 6),
		(null, 'analista de ventas', 2, 1), 
		(null, 'gerente de ventas', 7, 1), 
		(null, 'técnico de soporte', 3, 5), 
		(null, 'especialista de experiencias', 4, 2), 
		(null, 'coordinador de experiencias', 5, 2), 
		(null, 'supervisor de experiencias', 6, 2), 
		(null, 'gerente de experiencias', 7, 2), 
		(null, 'director administrativo', 8, 3), 
		(null, 'director de ventas', 9, 1), 
		(null, 'vendedor', 4, 1), 
		(null, 'coordinador de ventas', 5, 1), 
		(null, 'ejecutivo de cuentas', 4, 3), 
		(null, 'especialista en RH', 4, 4), 
		(null, 'gerente de RH', 7, 4),
		(null, 'especialista en sistemas y TI', 4, 5),
		(null, 'analista de datos estratégicos', 6, 6),
		(null, 'gerente de administrativo', 7, 3), 
		(null, 'jefe de equipo', 6, 2); 
        
INSERT INTO empleados(id_employee,employee_name, phone, email, address, rfc_employee, salary, employee_bank_name,employee_bank_account, hiring_date, id_location, id_position)
VALUES  (NULL, 'Gabriela Morales', '7775896412', 'gabriela@despegar.com', 'Paseo del conquistador #403 Colonia Las Haciendas', 'MOSA854697235', 35000, 'BBVA', '258963147854', '2021-02-01', 10, 1),
		(NULL, 'José García', '5557778888', 'jose@despegar.com', 'Avenida de los Trabajadores #105 Colonia Centro', 'GARJ852369741', 7000, 'Bancomer', '123654789012', '2021-02-01', 1, 2),
		(NULL, 'Laura Martínez', '5551234567', 'laura@despegar.com', 'Calle de las Flores #23 Colonia Primavera', 'MARL369852147', 8000, 'Bancomer', '789123456789', '2021-02-01', 3, 3),
		(NULL, 'Carlos Hernández', '5556667777', 'carlos@despegar.com', 'Calle del Sol #12 Colonia Aurora', 'HECA741258963', 7000, 'Banamex', '456789123456', '2021-02-01', 6, 4),
		(NULL, 'Ana Ramírez', '5557778888', 'ana@despegar.com', 'Calle de la Luna #45 Colonia Luna Nueva', 'RAAN963741852', 7000, 'Santander', '789456123789', '2021-02-01', 6, 5),
		(NULL, 'Diego Martínez', '5557779999', 'diego@despegar.com', 'Avenida del Bosque #67 Colonia Bosques del Sur', 'MADI852369741', 10000, 'Banorte', '147258369147', '2021-02-01', 1, 6),
		(NULL, 'María González', '5553334444', 'maria@despegar.com', 'Calle de la Montaña #89 Colonia Vista Hermosa', 'GOMA369852147', 15000, 'Santander', '987654123987', '2021-02-01', 1, 7),
		(NULL, 'Juan Pérez', '5556661111', 'juan@despegar.com', 'Calle de los Ingenieros #34 Colonia Tecnológica', 'PEJU852369741', 9000, 'HSBC', '369258147852', '2021-02-01', 5, 8),
		(NULL, 'Laura Gutiérrez', '5558889999', 'laura.g@despegar.com', 'Avenida de la Naturaleza #56 Colonia La Sierra', 'GULA963852741', 11000, 'BBVA', '987654321654', '2021-02-01', 2, 9),
		(NULL, 'Pedro Hernández', '5552223333', 'pedro.h@despegar.com', 'Calle del Río #78 Colonia del Bosque', 'HEPE963852741', 13000, 'Bancomer', '852963741852', '2021-02-01', 2, 10),
		(NULL, 'María López', '5555555555', 'maria.l@despegar.com', 'Avenida de los Pinos #90 Colonia de los Árboles', 'LOMA963852741', 14000, 'BBVA', '123456789654', '2021-02-01', 2, 11),
		(NULL, 'Javier Rodríguez', '5553334444', 'javier@despegar.com', 'Calle de las Aves #12 Colonia del Sol', 'ROJA963852741', 16000, 'Santander', '789456123987', '2021-02-01', 2, 12),
		(NULL, 'Fernando Díaz', '5556667777', 'fernando@despegar.com', 'Calle de las Flores #23 Colonia Primavera', 'DIFE963852741', 20000, 'Bancomer', '321654987321', '2021-02-01', 3, 13),
		(NULL, 'Carmen González', '5552223333', 'carmen@despegar.com', 'Calle de los Ángeles #45 Colonia Cielo Azul', 'GOCG963852741', 25000, 'BBVA', '987654321789', '2021-02-01', 1, 14),
		(NULL, 'Roberto Sánchez', '5558889999', 'roberto@despegar.com', 'Avenida del Trabajo #67 Colonia Centro', 'SARO963852741', 10000, 'Banamex', '456987321654', '2021-02-01', 1, 15),
		(NULL, 'Laura Martínez', '5551234567', 'laura.m@despegar.com', 'Calle del Trébol #89 Colonia Arcoiris', 'MALA963852741', 12000, 'BBVA', '789654321987', '2021-02-01', 1, 16),
		(NULL, 'María Pérez', '5557779999', 'maria.p@despegar.com', 'Calle de las Rosas #12 Colonia Jardín', 'PEMA963852741', 10000, 'Bancomer', '369258147852', '2021-02-01', 3, 17),
		(NULL, 'Diego Gómez', '5554445555', 'diego.g@despegar.com', 'Avenida de las Estrellas #34 Colonia Los Alamos', 'GODI963852741', 12000, 'BBVA', '987654321147', '2021-02-01', 4, 18),
		(NULL, 'Ana Rodríguez', '5558889999', 'ana.r@despegar.com', 'Calle de la Luna #67 Colonia Lunas', 'ROAN963852741', 15000, 'Santander', '123456789654', '2021-02-01', 4, 19),
		(NULL, 'Sofía García', '5556667777', 'sofia@despegar.com', 'Calle de las Nubes #12 Colonia Cielo', 'GASO963852741', 12000, 'HSBC', '321654987987', '2021-02-01', 5, 20),
		(NULL, 'Miguel López', '5551112222', 'miguel@despegar.com', 'Calle del Trueno #34 Colonia Tormenta', 'LOMI963852741', 14000, 'Banorte', '789456123321', '2021-02-01', 6, 21),
		(NULL, 'Laura Torres', '5559990000', 'laura.t@despegar.com', 'Calle del Río #56 Colonia del Sol', 'TOLA963852741', 16000, 'BBVA', '987654321456', '2021-02-01', 3, 22),
		(NULL, 'Juan Martínez', '5554445555', 'juan.m@despegar.com', 'Avenida de los Árboles #78 Colonia Arboledas', 'MAJU963852741', 15000, 'Banamex', '369258147369', '2021-02-01', 2, 23);
        
INSERT INTO categoria_actividades(id_category, category_name)
VALUES  (null, 'senderismo'),
		(null, 'escalada'),
        (null, 'bici de montaña'),
        (null, 'camping'),
        (null, 'ecoturismo'),
        (null, 'hibrido');
        
INSERT INTO proveedores_experiencias(id_supplier, company_name, phone, email, main_contact_name, payment_method, bank_name, bank_account, supplier_rfc, id_location)
VALUES  (null, 'Ecoturismo y Aventura NaturaPro', '5552693228', 'ecoturismoyave@gmail.com', 'Fernando Rosique', 'Transferencia bancaria', 'BBVA', '258964783214', 'EMYA846924IG8', 4),
		(null, 'Aventuras Extremas México', '5551234567', 'info@aventurasextremas.com', 'Laura Martínez', 'Transferencia bancaria', 'Bancomer', '123456789012', 'AEXM123456123', 3),
		(null, 'Turismo Aventura Maya', '5559876543', 'info@tama.com.mx', 'José García', 'Transferencia bancaria', 'Banorte', '987654321098', 'TAMX987654321', 12),
		(null, 'EcoTours México', '5555555555', 'contacto@ecotours.com.mx', 'María López', 'Transferencia bancaria', 'HSBC', '543216789012', 'EMMX987654321', 20),
		(null, 'Aventuras Yucatán', '5552223333', 'info@aventyuc.com', 'Pedro Hernández', 'Transferencia bancaria', 'BBVA Bancomer', '987654321001', 'AYM987654ZXC', 9),
		(null, 'Turismo de Aventura Chiapas', '5556667777', 'info@turaventchiapas.com', 'Sofía García', 'Cheque de caja', 'Santander', '789012345678', 'TAC987654321', 28),
		(null, 'Rutas de Aventura Sinaloa', '5553334444', 'contacto@rutasaventura.com', 'Javier Rodríguez', 'Transferencia bancaria', 'Scotiabank', '345678901234', 'RAS987654321', 21),
		(null, 'Viajes Extremos Baja', '5557778888', 'info@viajesextremosbaja.com', 'Ana Ramírez', 'Transferencia bancaria', 'Banamex', '234567890123', 'VEB987654321', 10),
		(null, 'Aventuras de la Riviera', '5558889999', 'contacto@aventurasriviera.com', 'Carlos Fernández', 'Transferencia bancaria', 'Inbursa', '456789012345', 'ARX987654321', 12),
		(null, 'Turismo de Aventura Sonora', '5554445555', 'info@turaventsonora.com', 'Laura Jiménez', 'Transferencia bancaria', 'Banorte', '567890123456', 'TASX987654321', 18),
		(null, 'Ecoturismo y Naturaleza Coahuila', '5550001111', 'info@ecoturcoahuila.com', 'Miguel Sánchez', 'Cheque de caja', 'HSBC', '678901234567', 'ENC987654321', 16),
		(null, 'Aventuras Tamaulipas', '5559990000', 'info@aventurastamps.com', 'Patricia Torres', 'Cheque al portador', 'BBVA Bancomer', '789012345678', 'ATM987654321', 8),
		(null, 'Turismo Extremo Guerrero', '5551112222', 'contacto@turaventguerrero.com', 'David Pérez', 'Transferencia bancaria', 'Santander', '890123456789', 'TEG987654321', 11),
		(null, 'Aventuras Quintana Roo', '5552223333', 'info@aventurasqr.com', 'Carmen González', 'Cheque de caja', 'Banamex', '901234567890', 'AQR987654321', 12),
		(null, 'Rutas de Aventura Michoacán', '5556667777', 'info@rutasaventura.com', 'Fernando Díaz', 'Transferencia bancaria', 'Scotiabank', '123456789012', 'RAM987654321', 23),
		(null, 'Ecotours Veracruz', '5553334444', 'contacto@ecotoursver.com', 'Sara García', 'Transferencia bancaria', 'Inbursa', '234567890123', 'EVX987654321', 14),
		(null, 'Turismo de Naturaleza Morelos', '5557778888', 'info@tunamor.com.mx', 'Diego Martínez', 'Transferencia bancaria', 'Banorte', '345678901234', 'TUNM987654321', 15),
		(null, 'Aventuras en San Luis Potosí', '5558889999', 'info@aventurasslp.com', 'Ana Rodríguez', 'Cheque de caja', 'Banamex', '456789012345', 'ASSP987654321', 26),
		(null, 'Turismo Extremo Oaxaca', '5554445555', 'info@turaventoax.com', 'Juan Ramírez', 'Transferencia bancaria', 'HSBC', '567890123456', 'TEO987654321', 28),
		(null, 'Ecoturismo Nayarit', '5550001111', 'contacto@ecoturnay.com', 'Elena López', 'Transferencia bancaria', 'BBVA Bancomer', '678901234567', 'EYN987654321', 29),
		(null, 'Aventuras de Jalisco', '5559990000', 'info@aventurasjal.com', 'Roberto Hernández', 'Transferencia bancaria', 'Banorte', '789012345678', 'AJX987654321', 3);
        
INSERT INTO experiencias_tours(id_experience, experience_name, id_category, experience_description, duration, requirements_restrictions, price_per_person, payment_agreement_percent, id_location, id_supplier)
VALUES  (null, 'Exploración en la selva maya', 5, 'Excursión para descubrir la flora y fauna de la selva maya.', 6, 'No apto para niños menores de 10 años. Clima húmedo y caluroso.', 1200, 25, 12, 3),
		(null, 'Escalada en la Sierra Madre', 2, 'Subida a los picos más altos de la Sierra Madre.', 8, 'Experiencia apta para escaladores con experiencia previa.', 1800, 20, 4, 8),
		(null, 'Ruta en bicicleta por las montañas', 3, 'Recorrido en bicicleta por las montañas de Baja California.', 4, 'Nivel de dificultad intermedio. No apto para niños menores de 12 años.', 800, 30, 10, 5),
		(null, 'Campamento en la playa', 4, 'Experiencia de camping en las costas de Quintana Roo.', 24, 'Necesario tener equipo de camping propio.', 2500, 40, 12, 1),
		(null, 'Avistamiento de ballenas', 5, 'Excursión en barco para avistar ballenas en las costas de Baja California.', 12, 'Se recomienda llevar protector solar y ropa ligera.', 2200, 35, 6, 2),
		(null, 'Senderismo en la sierra de Oaxaca', 1, 'Caminata por los senderos de la sierra de Oaxaca.', 10, 'Experiencia apta para toda la familia.', 1500, 25, 28, 19),
		(null, 'Recorrido en kayak por el río', 5, 'Viaje en kayak por el río Colorado.', 6, 'No apto para personas con problemas de espalda.', 1200, 30, 14, 7),
		(null, 'Espeleología en las cuevas de Chiapas', 5, 'Exploración de las cuevas y cavernas de Chiapas.', 8, 'Experiencia físicamente demandante. No apto para claustrofóbicos.', 1800, 25, 20, 6),
		(null, 'Visita guiada a zonas arqueológicas', 5, 'Tour guiado por las ruinas mayas en Yucatán.', 6, 'Recomendado llevar agua y calzado cómodo.', 1300, 30, 9, 3),
		(null, 'Tour en bicicleta por la ciudad', 3, 'Paseo en bicicleta por las principales atracciones de la ciudad de México.', 4, 'Experiencia apta para todo público. Se proporciona casco y bicicleta.', 800, 20, 1, 9),
		(null, 'Observación de aves en Veracruz', 5, 'Tour para la observación de aves en la reserva ecológica de Veracruz.', 6, 'Recomendado llevar binoculares y cámara fotográfica.', 1100, 30, 14, 16),
		(null, 'Recorrido en cuatrimoto por la sierra', 3, 'Paseo en cuatrimoto por las montañas de Guerrero.', 5, 'No apto para personas con problemas de espalda.', 1000, 25, 11, 13),
		(null, 'Excursión a cenotes en Yucatán', 5, 'Visita a los cenotes de la península de Yucatán.', 8, 'Necesario llevar traje de baño y toalla.', 1500, 30, 9, 5),
		(null, 'Rappel en cascadas de Chiapas', 2, 'Descenso en rappel por las cascadas de Chiapas.', 6, 'Experiencia apta para principiantes. No apto para personas con vértigo.', 1400, 25, 20, 6),
		(null, 'Observación de estrellas en Tamaulipas', 5, 'Tour nocturno para la observación de estrellas en el desierto de Tamaulipas.', 4, 'Recomendado llevar ropa abrigada y linterna.', 900, 30, 8, 12),
		(null, 'Tour en lancha por los manglares', 5, 'Paseo en lancha por los manglares de Sinaloa.', 6, 'Se proporciona protector solar y repelente de mosquitos.', 1200, 25, 21, 7),
		(null, 'Recorrido en jeep por la selva', 5, 'Viaje en jeep por las selvas de Quintana Roo.', 8, 'Experiencia apta para toda la familia.', 1600, 30, 12, 1),
		(null, 'Senderismo en los volcanes de Colima', 1, 'Caminata por los senderos de los volcanes de Colima.', 10, 'Recomendado llevar agua y botiquín básico.', 1300, 25, 24, 9),
		(null, 'Buceo en la barrera coralina', 5, 'Inmersión en las aguas de la barrera coralina en Quintana Roo.', 6, 'Experiencia apta para buzos certificados.', 1800, 35, 12, 4),
		(null, 'Vuelo en parapente sobre la sierra', 6, 'Experiencia de vuelo en parapente sobre la sierra de San Luis Potosí.', 4, 'No apto para personas con vértigo.', 1000, 30, 26, 18),
		(null, 'Recorrido en balsa por el río', 5, 'Paseo en balsa por el río Papagayo en Chiapas.', 6, 'Se proporciona chaleco salvavidas y equipo de seguridad.', 1100, 25, 20, 6),
		(null, 'Excursión a cascadas en Veracruz', 5, 'Visita a las cascadas de Agua Azul en Veracruz.', 8, 'Recomendado llevar traje de baño y toalla.', 1400, 30, 14, 16),
		(null, 'Tour de observación de ballenas', 5, 'Avistamiento de ballenas en la costa de Baja California.', 6, 'Recomendado llevar binoculares y cámara fotográfica.', 1200, 25, 6, 5),
		(null, 'Ruta en bicicleta por el bosque', 3, 'Recorrido en bicicleta por los bosques de Tamaulipas.', 5, 'Experiencia apta para toda la familia.', 1000, 30, 8, 12),
		(null, 'Campamento en la sierra de Oaxaca', 4, 'Experiencia de camping en las montañas de Oaxaca.', 24, 'Necesario tener equipo de camping propio.', 2500, 40, 28, 19),
		(null, 'Caminata en el Nevado de Toluca', 1, 'Senderismo en las faldas del Nevado de Toluca.', 8, 'Recomendado llevar agua y ropa abrigada.', 1300, 25, 17, 3),
		(null, 'Avistamiento de aves en Campeche', 5, 'Tour para la observación de aves en las reservas de Campeche.', 6, 'Recomendado llevar binoculares y guía de aves.', 1100, 30, 22, 21),
		(null, 'Recorrido en kayak por el mar', 5, 'Viaje en kayak por la costa de Yucatán.', 6, 'No apto para personas con problemas de espalda.', 1200, 25, 9, 5),
		(null, 'Espeleología en las cuevas de Guerrero', 5, 'Exploración de las cuevas y cavernas de Guerrero.', 8, 'Experiencia físicamente demandante. No apto para claustrofóbicos.', 1800, 25, 11, 13),
		(null, 'Recorrido en jeep por el desierto', 5, 'Viaje en jeep por el desierto de Sonora.', 8, 'Experiencia apta para toda la familia.', 1600, 30, 18, 10),
		(null, 'Senderismo en la reserva de Xalapa', 1, 'Caminata por los senderos de la reserva ecológica de Xalapa.', 10, 'Recomendado llevar agua y repelente de mosquitos.', 1500, 25, 19, 20),
		(null, 'Tour de observación de estrellas', 5, 'Excursión nocturna para la observación de estrellas en la sierra de Chiapas.', 4, 'Recomendado llevar ropa abrigada y linterna.', 900, 30, 20, 6),
		(null, 'Ruta en bicicleta por el campo', 3, 'Recorrido en bicicleta por los campos de Culiacán.', 5, 'Experiencia apta para toda la familia.', 1000, 30, 21, 21),
		(null, 'Campamento en la reserva de Durango', 4, 'Experiencia de camping en la reserva natural de Durango.', 24, 'Necesario tener equipo de camping propio.', 2500, 40, 25, 7),
		(null, 'Buceo en la costa de Veracruz', 5, 'Inmersión en las aguas de la costa de Veracruz.', 6, 'Experiencia apta para buzos certificados.', 1800, 35, 14, 16),
		(null, 'Vuelo en parapente sobre la playa', 6, 'Experiencia de vuelo en parapente sobre las playas de Guerrero.', 4, 'No apto para personas con vértigo.', 1000, 30, 11, 13),
		(null, 'Recorrido en balsa por el río Coatzacoalcos', 5, 'Paseo en balsa por el río Coatzacoalcos en Veracruz.', 6, 'Se proporciona chaleco salvavidas y equipo de seguridad.', 1100, 25, 14, 16),
		(null, 'Visita a cascadas en Chiapas', 5, 'Excursión a las cascadas de Agua Azul en Chiapas.', 8, 'Recomendado llevar traje de baño y toalla.', 1400, 30, 20, 6),
		(null, 'Tour de avistamiento de aves', 5, 'Excursión para la observación de aves en la selva de Quintana Roo.', 6, 'Recomendado llevar binoculares y cámara fotográfica.', 1200, 25, 12, 1),
		(null, 'Paseo en bicicleta por la costa', 3, 'Recorrido en bicicleta por la costa de Sinaloa.', 5, 'Experiencia apta para toda la familia.', 1000, 30, 21, 7),    
		(null, 'Senderismo en el Nevado de Toluca', 1, 'Excursión guiada por los senderos del Nevado de Toluca con vistas panorámicas impresionantes', 6, 'No apto para niños menores de 12 años, llevar botas de montaña y abrigo', 850, 30, 15, 4),
		(null, 'Escalada en roca en Potrero Chico', 2, 'Diversos niveles de escalada en roca con guía experto en Potrero Chico, Nuevo León', 10, 'Experiencia ideal para escaladores intermedios, llevar equipo de escalada', 1500, 40, 4, 8),
		(null, 'Ruta en bicicleta por la Selva Lacandona', 3, 'Recorrido en bicicleta a través de la exuberante Selva Lacandona, en Chiapas', 12, 'Apto para niños mayores de 10 años, llevar agua y repelente de insectos', 1200, 25, 20, 6),
		(null, 'Acampada bajo las estrellas en Valle de Bravo', 4, 'Noche de acampada en Valle de Bravo con fogata, historia y mitología local', 1, 'No apto para personas con problemas de movilidad, llevar saco de dormir y linterna', 700, 20, 17, 12),
		(null, 'Avistamiento de aves en los manglares de Tulum', 5, 'Paseo en lancha por los manglares de Tulum para observar aves endémicas', 3, 'Recomendado para amantes de la naturaleza, llevar binoculares y cámara', 800, 25, 12, 3),
		(null, 'Senderismo en el Parque Nacional Cumbres de Monterrey', 1, 'Exploración de senderos y cascadas en el Parque Nacional Cumbres de Monterrey', 8, 'No apto para personas con vértigo, llevar calzado antideslizante y gorra', 1000, 30, 4, 2),
		(null, 'Escalada en roca en Peña de Bernal', 2, 'Ascenso guiado a la majestuosa Peña de Bernal, uno de los monolitos más grandes del mundo', 6, 'Experiencia apta para principiantes, llevar casco y arnés', 1200, 35, 17, 1),
		(null, 'Ruta en bicicleta por la Ruta del Vino en Ensenada', 3, 'Paseo en bicicleta por los viñedos de la Ruta del Vino en Ensenada, Baja California', 5, 'Recomendado para aficionados al vino, llevar protector solar y botella de agua', 900, 30, 10, 5),
		(null, 'Acampada en la Sierra Gorda de Querétaro', 4, 'Experiencia de acampada en la Sierra Gorda de Querétaro, rodeado de naturaleza', 2, 'No apto para personas con alergias, llevar tienda de campaña y repelente', 600, 20, 30, 7),
		(null, 'Avistamiento de ballenas en Los Cabos', 5, 'Emocionante paseo en barco para avistar ballenas en su hábitat natural', 2, 'Recomendado para amantes de la vida marina, llevar cámara y chaleco salvavidas', 1500, 40, 10, 7),
		(null, 'Senderismo en el Pico de Orizaba', 1, 'Ascenso guiado al Pico de Orizaba, la montaña más alta de México', 24, 'Experiencia solo para montañistas experimentados, llevar crampones y piolet', 2500, 50, 19, 15),
		(null, 'Espeleología en las Grutas de García', 2, 'Exploración de cuevas y cavernas en las Grutas de García, Nuevo León', 4, 'No apto para claustrofóbicos, llevar casco con linterna y ropa cómoda', 1100, 35, 4, 10),
		(null, 'Ruta en bicicleta por la Isla Holbox', 3, 'Paseo en bicicleta por las playas y calles de la hermosa Isla Holbox, Quintana Roo', 8, 'Apto para todos los niveles, llevar traje de baño y protector solar', 1200, 30, 12, 12),
		(null, 'Acampada en el Parque Nacional El Tepozteco', 4, 'Noche de acampada en el Parque Nacional El Tepozteco, rodeado de naturaleza y energía', 2, 'No apto para personas con alergias, llevar linterna y repelente de mosquitos', 700, 20, 15, 1),
		(null, 'Avistamiento de aves en la Reserva de la Biosfera de Calakmul', 5, 'Paseo en bicicleta por la Reserva de la Biosfera de Calakmul para observar aves exóticas', 6, 'Recomendado para amantes de la ornitología, llevar guía de aves y agua', 1000, 25, 20, 3),
		(null, 'Senderismo en el Parque Nacional Lagunas de Zempoala', 1, 'Recorrido por los senderos y lagunas del Parque Nacional Lagunas de Zempoala, Morelos', 4, 'No apto para personas con problemas cardíacos, llevar calzado adecuado y gorra', 800, 30, 15, 15),
		(null, 'Escalada en roca en El Salto', 2, 'Diversas rutas de escalada en roca en El Salto, Nayarit, con impresionantes vistas al mar', 6, 'Experiencia apta para escaladores avanzados, llevar equipo completo de escalada', 1300, 40, 20, 21),
		(null, 'Ruta en bicicleta por la Sierra Madre Occidental', 3, 'Paseo en bicicleta por la pintoresca Sierra Madre Occidental, Jalisco', 10, 'Apto para todos los niveles, llevar protección solar y botella de agua', 1500, 35, 3, 21),
		(null, 'Acampada en el Parque Nacional El Chico', 4, 'Noche de acampada en el Parque Nacional El Chico, Hidalgo, en medio de bosques de coníferas', 2, 'No apto para personas con alergias, llevar saco de dormir y linterna', 650, 25, 8, 18),
		(null, 'Avistamiento de aves en la Reserva de la Biosfera de la Sierra Gorda', 5, 'Paseo en lancha por la Reserva de la Biosfera de la Sierra Gorda para avistar aves', 4, 'Recomendado para amantes de la ornitología, llevar cámara y guía de aves', 900, 30, 30, 14),
		(null, 'Senderismo en el Parque Nacional Desierto de los Leones', 1, 'Exploración de los senderos y cascadas del Parque Nacional Desierto de los Leones, CDMX', 6, 'No apto para personas con problemas de movilidad, llevar calzado cómodo y gorra', 1000, 25, 1, 1),
		(null, 'Escalada en roca en Hierve el Agua', 2, 'Ascenso a las formaciones rocosas de Hierve el Agua, Oaxaca, con vistas panorámicas', 4, 'Experiencia apta para escaladores intermedios, llevar equipo de escalada y agua', 1200, 35, 28, 19),
		(null, 'Ruta en bicicleta por la Sierra Gorda de Querétaro', 3, 'Paseo en bicicleta por los paisajes de la Sierra Gorda de Querétaro, con paradas en miradores', 8, 'Apto para todos los niveles, llevar casco y protector solar', 1100, 30, 30, 17),
		(null, 'Acampada en el Parque Nacional El Tepozteco', 4, 'Noche de acampada en el Parque Nacional El Tepozteco, con vistas al Tepozteco y Tlayacapan', 2, 'No apto para personas con alergias, llevar tienda de campaña y repelente de insectos', 600, 20, 15, 7),
		(null, 'Avistamiento de aves en la Laguna de Términos', 5, 'Recorrido en lancha por la Laguna de Términos para avistar aves migratorias y cocodrilos', 4, 'Recomendado para amantes de la naturaleza, llevar cámara y binoculares', 1000, 30, 9, 2),
		(null, 'Senderismo en la Sierra de San Francisco', 1, 'Exploración de los petroglifos y cañones de la Sierra de San Francisco, Baja California Sur', 8, 'No apto para personas con problemas de rodilla, llevar botas de montaña y gorra', 1100, 25, 22, 20),
		(null, 'Escalada en roca en la Huasteca Potosina', 2, 'Ascenso a las impresionantes paredes de la Huasteca Potosina, con variedad de rutas de escalada', 6, 'Experiencia apta para escaladores intermedios, llevar equipo completo de escalada', 1300, 35, 26, 9),
		(null, 'Ruta en bicicleta por la Selva Negra', 3, 'Paseo en bicicleta por los senderos de la Selva Negra, Chiapas, con paradas en cascadas y cenotes', 10, 'Apto para todos los niveles, llevar repelente de insectos y agua', 1200, 30, 20, 6),
		(null, 'Acampada en el Parque Nacional Iztaccíhuatl-Popocatépetl', 4, 'Noche de acampada en el Parque Nacional Iztaccíhuatl-Popocatépetl, con vistas a los volcanes', 2, 'No apto para personas con problemas de movilidad, llevar saco de dormir y linterna', 650, 25, 15, 4),
		(null, 'Avistamiento de aves en la Reserva de la Biosfera de Sian Ka''an', 5, 'Paseo en lancha por la Reserva de la Biosfera de Sian Ka''an para observar aves y manatíes', 6, 'Recomendado para amantes de la ornitología y la vida marina, llevar cámara y binoculares', 900, 30, 12, 5),
		(null, 'Senderismo en la Sierra Gorda de Querétaro', 1, 'Exploración de los senderos y cascadas de la Sierra Gorda de Querétaro, con vistas panorámicas', 6, 'No apto para personas con problemas de movilidad, llevar calzado adecuado y gorra', 1000, 25, 30, 4),
		(null, 'Escalada en roca en la Huasteca Potosina', 2, 'Ascenso a las impresionantes paredes de la Huasteca Potosina, con variedad de rutas de escalada', 6, 'Experiencia apta para escaladores intermedios, llevar equipo completo de escalada', 1300, 35, 26, 9),
		(null, 'Ruta en bicicleta por la Selva Negra', 3, 'Paseo en bicicleta por los senderos de la Selva Negra, Chiapas, con paradas en cascadas y cenotes', 10, 'Apto para todos los niveles, llevar repelente de insectos y agua', 1200, 30, 20, 6),
		(null, 'Acampada en el Parque Nacional Iztaccíhuatl-Popocatépetl', 4, 'Noche de acampada en el Parque Nacional Iztaccíhuatl-Popocatépetl, con vistas a los volcanes', 2, 'No apto para personas con problemas de movilidad, llevar saco de dormir y linterna', 650, 25, 15, 4),
		(null, 'Avistamiento de aves en la Reserva de la Biosfera de Sian Ka''an', 5, 'Paseo en lancha por la Reserva de la Biosfera de Sian Ka''an para observar aves y manatíes', 6, 'Recomendado para amantes de la ornitología y la vida marina, llevar cámara y binoculares', 900, 30, 12, 5);
			


INSERT INTO clientes(id_customer, customer_name, email, phone, rfc_customer, id_location)
VALUES  (null, 'Gabriela Morales', 'gaby@gmail.com', '7775689932', 'MOEU589632IS8', 1),
		(null, 'Alejandro González', 'alejandro.gonzalez@gmail.com', '5551234567', 'GOEA920610KX1', 3),
		(null, 'Laura Ramírez', 'laura.ramirez@hotmail.com', '5552345678', 'RALO9001013Q9', 5),
		(null, 'Daniel López', 'daniel.lopez@yahoo.com', '5553456789', 'LODA890502MZA', 12),
        (null, 'Mariana Pérez', 'mariana.perez@gmail.com', '5554567890', 'PEMG850213FV0', 9),
		(null, 'José Rodríguez', 'jose.rodriguez@hotmail.com', '5555678901', 'ROJJ911203123', 20),
		(null, 'Ana Martínez', 'ana.martinez@yahoo.com', '5556789012', 'MARA800314MCD', 1),
		(null, 'Carlos Hernández', 'carlos.hernandez@gmail.com', '5557890123', 'HECC851229WY8', 15),
		(null, 'Sofía García', 'sofia.garcia@hotmail.com', '5558901234', 'GASO880426NJ9', 8),
		(null, 'Diego Torres', 'diego.torres@yahoo.com', '5559012345', 'TOND920920CF9', 10),
		(null, 'Fernanda Díaz', 'fernanda.diaz@gmail.com', '5550123456', 'DIFM850502MVL', 22),
		(null, 'Javier Ruiz', 'javier.ruiz@hotmail.com', '5551234567', 'RUIJ911023Y8R', 13),
		(null, 'Valeria Sánchez', 'valeria.sanchez@yahoo.com', '5552345678', 'SALV930306MTR', 14),
		(null, 'Ricardo Ramírez', 'ricardo.ramirez@gmail.com', '5553456789', 'RARO900101123', 2),
		(null, 'Paola Flores', 'paola.flores@hotmail.com', '5554567890', 'FOPA910304CR9', 11),
		(null, 'Andrés Gómez', 'andres.gomez@yahoo.com', '5555678901', 'GOEA921203DV8', 17),
		(null, 'Gabriela Ruiz', 'gabriela.ruiz@gmail.com', '5556789012', 'RUGA880426PQ1', 6),
		(null, 'Fernando Herrera', 'fernando.herrera@hotmail.com', '5557890123', 'HEFE870508M90', 28),
		(null, 'Mónica Molina', 'monica.molina@yahoo.com', '5558901234', 'MOMO8009145K2', 19),
		(null, 'Jorge Pérez', 'jorge.perez@gmail.com', '5559012345', 'PEOJ9209208K8', 24),
		(null, 'Ana María González', 'ana.gonzalez@hotmail.com', '5550123456', 'GOMA901012BX9', 26),
		(null, 'Luisa Rodríguez', 'luisa.rodriguez@yahoo.com', '5551234567', 'ROPL930516FE8', 27),
		(null, 'Mario Díaz', 'mario.diaz@gmail.com', '5552345678', 'DIMM910304RD9', 23),
		(null, 'Natalia Pérez', 'natalia.perez@hotmail.com', '5553456789', 'PENA870508KK8', 25),
		(null, 'Pedro Martínez', 'pedro.martinez@yahoo.com', '5554567890', 'MARP911023GN2', 29),
		(null, 'Daniela Gómez', 'daniela.gomez@gmail.com', '5555678901', 'GODA920610FN2', 30),
		(null, 'Raul Sánchez', 'raul.sanchez@hotmail.com', '5556789012', 'SARU9209203F2', 16),
		(null, 'Sara Flores', 'sara.flores@yahoo.com', '5557890123', 'FOSS850426VJ2', 18),
		(null, 'Elena Ruiz', 'elena.ruiz@gmail.com', '5558901234', 'RUEL800914YV5', 4),
		(null, 'Miguel López', 'miguel.lopez@hotmail.com', '5559012345', 'LOME921203KU3', 7),
		(null, 'Victoria Ramírez', 'victoria.ramirez@yahoo.com', '5550123456', 'RARI8705081Z2', 21),
		(null, 'Gabriel González', 'gabriel.gonzalez@gmail.com', '5551234567', 'GOGA900101B39', 30),
		(null, 'Valentina Hernández', 'valentina.hernandez@hotmail.com', '5552345678', 'HEVA9103049T7', 17),
		(null, 'Mateo Díaz', 'mateo.diaz@yahoo.com', '5553456789', 'DIMA920610FJ2', 10),
		(null, 'Fernanda Pérez', 'fernanda.perez@gmail.com', '5554567890', 'PEFE900101LH1', 1),
		(null, 'Juan Carlos Martínez', 'juan.martinez@hotmail.com', '5555678901', 'MAMJ930516KP3', 9),
		(null, 'Adriana Flores', 'adriana.flores@yahoo.com', '5556789012', 'FOAD920920VV8', 2),
		(null, 'Javier Rodríguez', 'javier.rodriguez@gmail.com', '5557890123', 'RORJ8504269G4', 19),
		(null, 'María Sánchez', 'maria.sanchez@hotmail.com', '5558901234', 'SAMA800914FG2', 8),
		(null, 'Carlos Torres', 'carlos.torres@yahoo.com', '5559012345', 'TOCA9212033V8', 15),
		(null, 'Paulina Gómez', 'paulina.gomez@gmail.com', '5550123456', 'GOPA870508HV3', 11),
		(null, 'Emilio Ramírez', 'emilio.ramirez@hotmail.com', '5551234567', 'RARO800101QC1', 12),
		(null, 'Sofía Martínez', 'sofia.martinez@yahoo.com', '5552345678', 'MASM921203FA8', 25),
		(null, 'Diego Hernández', 'diego.hernandez@gmail.com', '5553456789', 'HEMD8705083H9', 28),
		(null, 'Valeria Rodríguez', 'valeria.rodriguez@hotmail.com', '5554567890', 'RORV921203HD0', 4),
		(null, 'Manuel Flores', 'manuel.flores@yahoo.com', '5555678901', 'FOMA880426KK4', 23),
		(null, 'Lucía Gómez', 'lucia.gomez@gmail.com', '5556789012', 'GOLU901012M73', 6),
		(null, 'Mariano Ramírez', 'mariano.ramirez@hotmail.com', '5557890123', 'RARH920920RQ0', 30),
		(null, 'Cristina Sánchez', 'cristina.sanchez@yahoo.com', '5558901234', 'SACR8804268T8', 14),
		(null, 'Pablo Torres', 'pablo.torres@gmail.com', '5559012345', 'TOTP9212036U3', 3),
		(null, 'Ana Paula López', 'ana.lopez@hotmail.com', '5550123456', 'LOAP9305166D0', 21),
		(null, 'Gustavo Pérez', 'gustavo.perez@yahoo.com', '5551234567', 'PEGU910304DM4', 29),
		(null, 'María Fernanda García', 'maria.garcia@gmail.com', '5552345678', 'GAFM8001018C9', 13),
		(null, 'Joaquín Ramírez', 'joaquin.ramirez@hotmail.com', '5553456789', 'RARJ9305164U3', 27),
		(null, 'Fernanda Martínez', 'fernanda.martinez@yahoo.com', '5554567890', 'MAMF900101UP3', 18),
		(null, 'Luis Rodríguez', 'luis.rodriguez@gmail.com', '5555678901', 'RORL9110231G5', 26),
		(null, 'Carolina Sánchez', 'carolina.sanchez@hotmail.com', '5556789012', 'SACA8804264H9', 7),
		(null, 'Andrés Torres', 'andres.torres@yahoo.com', '5557890123', 'TOTR870508UC2', 16),
		(null, 'Laura Gómez', 'laura.gomez@gmail.com', '5558901234', 'GOLA9001019N4', 22),
		(null, 'Miguel Ángel Martínez', 'miguel.martinez@hotmail.com', '5559012345', 'MAMM921203FT5', 5),
		(null, 'Sofía Hernández', 'sofia.hernandez@yahoo.com', '5550123456', 'HESS900101UG0', 9),
		(null, 'Diego Ramírez', 'diego.ramirez@gmail.com', '5551234567', 'RARD9212032P7', 24),
		(null, 'Ana Karen Pérez', 'ana.perez@hotmail.com', '5552345678', 'PEAK930516MM5', 20),
		(null, 'Juan Carlos Gómez', 'juan.gomez@yahoo.com', '5553456789', 'GOCJ800101V91', 1),
		(null, 'María José Rodríguez', 'maria.rodriguez@gmail.com', '5554567890', 'RORM900101AV2', 8),
		(null, 'Fernando Torres', 'fernando.torres@hotmail.com', '5555678901', 'TOTF930516HV8', 10),
		(null, 'Valentina Martínez', 'valentina.martinez@yahoo.com', '5556789012', 'MAMV800101UN6', 19),
		(null, 'Miguel Ángel Sánchez', 'miguel.sanchez@gmail.com', '5557890123', 'SAMM900101JK9', 14),
		(null, 'Sara Torres', 'sara.torres@hotmail.com', '5558901234', 'TOTM8705081V1', 6),
		(null, 'Rodrigo Flores', 'rodrigo.flores@yahoo.com', '5559012345', 'FORO900101K59', 29),
		(null, 'María Fernanda López', 'maria.lopez@gmail.com', '5550123456', 'LOFM9110234A4', 30),
		(null, 'Joaquín Hernández', 'joaquin.hernandez@hotmail.com', '5551234567', 'HEJQ900101KN6', 16),
		(null, 'Valeria Ramírez', 'valeria.ramirez@yahoo.com', '5552345678', 'RAVA900101BQ1', 22),
		(null, 'Diego Martínez', 'diego.martinez@gmail.com', '5553456789', 'MADI900101HHA', 11),
		(null, 'Ana Sofía Pérez', 'ana.perez@hotmail.com', '5554567890', 'PEAS900101N77', 28),
		(null, 'Emilio Gómez', 'emilio.gomez@yahoo.com', '5555678901', 'GOEM900101B79', 15),
		(null, 'Fernanda García', 'fernanda.garcia@gmail.com', '5556789012', 'GAFE910304K19', 17),
		(null, 'Juan Pérez', 'juan.perez@hotmail.com', '5557890123', 'PEJU900101PL1', 3),
		(null, 'Sofía Martínez', 'sofia.martinez@yahoo.com', '5558901234', 'MASM911023GV5', 2),
		(null, 'Miguel Ángel Torres', 'miguel.torres@gmail.com', '5559012345', 'TOMA900101FT9', 25),
		(null, 'Valentina Flores', 'valentina.flores@hotmail.com', '5550123456', 'FOVA880426H2A', 24),
		(null, 'Pedro Ramírez', 'pedro.ramirez@yahoo.com', '5551234567', 'RARO930516MZ4', 7),
		(null, 'Ana Karen Sánchez', 'ana.sanchez@gmail.com', '5552345678', 'SAAA9001011B1', 8),
		(null, 'Juan José Hernández', 'juan.hernandez@hotmail.com', '5553456789', 'HEJJ900101M33', 4),
		(null, 'Valeria Martínez', 'valeria.martinez@yahoo.com', '5554567890', 'MAVM900101BT5', 5),
		(null, 'Miguel Ángel Gómez', 'miguel.gomez@gmail.com', '5555678901', 'GOAM8001018E8', 12),
		(null, 'Sofía García', 'sofia.garcia@hotmail.com', '5556789012', 'GASF8705084G2', 9),
		(null, 'Emilio Torres', 'emilio.torres@yahoo.com', '5557890123', 'TOEM9001016R5', 19),
		(null, 'Fernanda Rodríguez', 'fernanda.rodriguez@gmail.com', '5558901234', 'RORF870508L94', 21),
		(null, 'Juan Carlos López', 'juan.lopez@hotmail.com', '5559012345', 'LOJU900101KJ6', 18),
		(null, 'Ana Sofía Gómez', 'ana.gomez@yahoo.com', '5550123456', 'GOAS930516M8A', 23),
		(null, 'Emiliano Sánchez', 'emiliano.sanchez@gmail.com', '5551234567', 'SAEM800101V87', 20),
		(null, 'María José Martínez', 'maria.martinez@hotmail.com', '5552345678', 'MAMJ800101KJ4', 26),
		(null, 'Joaquín Pérez', 'joaquin.perez@yahoo.com', '5553456789', 'PEJO9001012A8', 1),
		(null, 'Andrés García', 'andres.garcia@gmail.com', '5554567890', 'GAAA8804269Q8', 13),
		(null, 'Gabriela Torres', 'gabriela.torres@hotmail.com', '5555678901', 'TOGA9001016G6', 30),
		(null, 'Luisa Sánchez', 'luisa.sanchez@yahoo.com', '5556789012', 'SALU900101IM3', 14),
		(null, 'Alejandro Gómez', 'alejandro.gomez@gmail.com', '5557890123', 'GOAL800101Q88', 7),
		(null, 'Fernanda Martínez', 'fernanda.martinez@hotmail.com', '5558901234', 'MAMF9001019U1', 6),
		(null, 'Juan José Ramírez', 'juan.ramirez@yahoo.com', '5559012345', 'RARJ900101PQ3', 10),
		(null, 'Valentina López', 'valentina.lopez@gmail.com', '5550123456', 'LOVA800101IM3', 2),
		(null, 'Sofía Martínez', 'sofia.martinez@hotmail.com', '5551234567', 'MASM8705081Q5', 22),
		(null, 'Emiliano Rodríguez', 'emiliano.rodriguez@yahoo.com', '5552345678', 'RORC900101FC8', 11),
		(null, 'María José García', 'maria.garcia@gmail.com', '5553456789', 'GAMJ8804269P9', 26),
		(null, 'Joaquín López', 'joaquin.lopez@hotmail.com', '5554567890', 'LOJO900101FC2', 24);
 

-- --------- END TRIGGER PRE- VENTAS --------------------------
 
INSERT INTO ventas(id_sale_transaction,id_customer,id_experience, sale_date, experience_date, group_size, amount_total, id_employee_sale, notes)
VALUES 	(NULL, 48, 17, '2023-03-10', '2023-03-14', 4, NULL, 6, NULL),
		(NULL, 92, 62, '2023-04-22', '2023-04-25', 3, NULL, 15, NULL),
		(NULL, 19, 51, '2023-03-01', '2023-03-03', 2, NULL, 14, NULL),
		(NULL, 74, 5, '2023-04-01', '2023-04-03', 7, NULL, 3, NULL),
		(NULL, 101, 29, '2024-02-28', '2024-03-02', 3, NULL, 7, NULL),
		(NULL, 85, 40, '2023-03-17', '2023-03-20', 3, NULL, 15, NULL),
		(NULL, 57, 33, '2023-03-05', '2023-03-09', 5, NULL, 14, NULL),
		(NULL, 29, 18, '2023-02-27', '2023-03-02', 4, NULL, 16, NULL),
		(NULL, 93, 68, '2024-03-28', '2024-03-31', 3, NULL, 16, NULL),
		(NULL, 84, 45, '2023-03-21', '2023-03-24', 2, NULL, 14, NULL),
		(NULL, 42, 60, '2023-04-08', '2023-04-11', 4, NULL, 6, NULL),
		(NULL, 62, 71, '2023-04-16', '2023-04-19', 2, NULL, 15, NULL),
		(NULL, 105, 9, '2024-02-24', '2024-02-27', 8, NULL, 3, NULL),
		(NULL, 2, 38, '2023-03-01', '2023-03-05', 6, NULL, 15, NULL),
		(NULL, 37, 16, '2023-03-04', '2023-03-08', 3, NULL, 6, NULL),
		(NULL, 80, 13, '2023-03-19', '2023-03-22', 2, NULL, 7, NULL),
		(NULL, 45, 28, '2023-03-07', '2023-03-11', 4, NULL, 6, NULL),
		(NULL, 20, 23, '2023-03-01', '2023-03-03', 3, NULL, 7, NULL),
		(NULL, 63, 48, '2023-04-13', '2023-04-16', 5, NULL, 14, NULL),
		(NULL, 89, 59, '2023-04-01', '2023-04-05', 3, NULL, 14, NULL),
		(NULL, 55, 12, '2023-03-04', '2023-03-07', 4, NULL, 15, NULL),
		(NULL, 16, 65, '2023-03-01', '2023-03-05', 3, NULL, 14, NULL),
		(NULL, 46, 41, '2023-03-08', '2023-03-11', 6, NULL, 3, NULL),
		(NULL, 76, 72, '2023-03-22', '2023-03-25', 2, NULL, 16, NULL),
		(NULL, 82, 22, '2023-03-19', '2023-03-22', 5, NULL, 15, NULL),
		(NULL, 13, 8, '2023-03-03', '2023-03-06', 3, NULL, 14, NULL),
		(NULL, 1, 53, '2023-02-26', '2023-03-02', 2, NULL, 3, NULL),
		(NULL, 98, 66, '2023-04-26', '2023-04-30', 7, NULL, 6, NULL),
		(NULL, 72, 25, '2023-03-14', '2023-03-17', 2, NULL, 14, NULL),
		(NULL, 9, 57, '2023-03-01', '2023-03-04', 4, NULL, 6, NULL),
		(NULL, 64, 30, '2023-08-15', '2023-08-18', 3, NULL, 14, NULL),
		(NULL, 21, 45, '2023-10-05', '2023-10-08', 3, NULL, 3, NULL),
		(NULL, 92, 18, '2023-12-20', '2023-12-23', 4, NULL, 6, NULL),
		(NULL, 7, 63, '2024-02-29', '2024-03-03', 8, NULL, 14, NULL),
		(NULL, 49, 19, '2023-05-17', '2023-05-20', 2, NULL, 15, NULL),
		(NULL, 87, 56, '2024-03-08', '2024-03-11', 5, NULL, 3, NULL),
		(NULL, 33, 71, '2023-07-09', '2023-07-12', 3, NULL, 14, NULL),
		(NULL, 12, 9, '2024-04-01', '2024-04-04', 4, NULL, 15, NULL),
		(NULL, 45, 52, '2024-01-22', '2024-01-25', 2, NULL, 14, NULL),
		(NULL, 82, 8, '2023-09-05', '2023-09-08', 3, NULL, 16, NULL),
		(NULL, 97, 36, '2023-11-11', '2023-11-14', 5, NULL, 14, NULL),
		(NULL, 14, 12, '2024-04-25', '2024-04-28', 4, NULL, 7, NULL),
		(NULL, 71, 68, '2023-06-30', '2023-07-03', 2, NULL, 6, NULL),
		(NULL, 36, 39, '2023-12-03', '2023-12-06', 3, NULL, 15, NULL),
		(NULL, 63, 58, '2023-05-09', '2023-05-12', 4, NULL, 3, NULL),
		(NULL, 5, 16, '2023-08-20', '2023-08-23', 8, NULL, 7, NULL),
		(NULL, 28, 42, '2023-10-29', '2023-11-01', 5, NULL, 16, NULL),
		(NULL, 80, 75, '2023-06-10', '2023-06-13', 2, NULL, 15, NULL),
		(NULL, 51, 26, '2023-09-19', '2023-09-22', 3, NULL, 6, NULL),
		(NULL, 19, 10, '2023-11-23', '2023-11-26', 3, NULL, 14, NULL),
		(NULL, 94, 47, '2024-02-15', '2024-02-18', 8, NULL, 16, NULL),
		(NULL, 40, 28, '2023-07-22', '2023-07-25', 4, NULL, 6, NULL),
		(NULL, 17, 67, '2023-12-30', '2024-01-02', 3, NULL, 3, NULL),
		(NULL, 75, 20, '2023-04-18', '2023-04-21', 3, NULL, 15, NULL),
		(NULL, 2, 51, '2024-03-20', '2024-03-23', 2, NULL, 14, NULL),
		(NULL, 68, 22, '2023-05-28', '2023-05-31', 5, NULL, 7, NULL),
		(NULL, 42, 38, '2024-01-03', '2024-01-06', 3, NULL, 16, NULL),
		(NULL, 89, 61, '2023-07-16', '2023-07-19', 8, NULL, 6, NULL),
		(NULL, 16, 13, '2023-10-19', '2023-10-22', 3, NULL, 15, NULL),
		(NULL, 59, 70, '2023-05-01', '2023-05-04', 4, NULL, 3, NULL),
		(NULL, 103, 60, '2023-06-15', '2023-06-18', 4, NULL, 15, NULL),
		(NULL, 27, 17, '2023-08-02', '2023-08-05', 3, NULL, 7, NULL),
		(NULL, 84, 34, '2023-10-25', '2023-10-28', 5, NULL, 14, NULL),
		(NULL, 9, 24, '2024-01-12', '2024-01-15', 8, NULL, 16, NULL),
		(NULL, 58, 72, '2023-06-08', '2023-06-11', 4, NULL, 14, NULL),
		(NULL, 24, 55, '2024-04-08', '2024-04-11', 2, NULL, 3, NULL),
		(NULL, 77, 14, '2023-05-25', '2023-05-28', 3, NULL, 16, NULL),
		(NULL, 48, 33, '2023-09-05', '2023-09-08', 5, NULL, 7, NULL),
		(NULL, 85, 43, '2023-11-26', '2023-11-29', 3, NULL, 14, NULL),
		(NULL, 32, 57, '2024-02-01', '2024-02-04', 5, NULL, 15, NULL),
		(NULL, 99, 11, '2023-07-13', '2023-07-16', 4, NULL, 3, NULL),
		(NULL, 56, 66, '2024-01-29', '2024-02-01', 8, NULL, 6, NULL),
		(NULL, 22, 23, '2023-04-04', '2023-04-07', 3, NULL, 15, NULL),
		(NULL, 89, 49, '2023-06-01', '2023-06-04', 3, NULL, 14, NULL),
		(NULL, 13, 15, '2023-10-08', '2023-10-11', 4, NULL, 7, NULL),
		(NULL, 71, 69, '2024-02-17', '2024-02-20', 2, NULL, 16, NULL),
		(NULL, 44, 53, '2023-08-12', '2023-08-15', 5, NULL, 6, NULL),
		(NULL, 76, 21, '2023-11-02', '2023-11-05', 3, NULL, 15, NULL),
		(NULL, 6, 46, '2023-04-26', '2023-04-29', 4, NULL, 3, NULL),
		(NULL, 37, 31, '2023-07-05', '2023-07-08', 2, NULL, 14, NULL),
		(NULL, 94, 62, '2023-09-29', '2023-10-02', 3, NULL, 15, NULL),
		(NULL, 67, 64, '2024-01-16', '2024-01-19', 4, NULL, 7, NULL),
		(NULL, 15, 29, '2023-05-16', '2023-05-19', 8, NULL, 16, NULL),
		(NULL, 82, 73, '2023-08-29', '2023-09-01', 3, NULL, 15, NULL),
		(NULL, 29, 35, '2023-11-19', '2023-11-22', 3, NULL, 6, NULL),
		(NULL, 75, 54, '2023-07-30', '2023-08-02', 5, NULL, 15, NULL),
		(NULL, 42, 25, '2023-10-22', '2023-10-25', 3, NULL, 14, NULL),
		(NULL, 88, 59, '2024-02-12', '2024-02-15', 2, NULL, 3, NULL),
		(NULL, 18, 74, '2023-05-23', '2023-05-26', 4, NULL, 16, NULL),
		(NULL, 63, 32, '2023-09-15', '2023-09-18', 3, NULL, 15, NULL),
		(NULL, 22, 44, '2023-08-10', '2023-08-13', 4, NULL, 3, NULL),
		(NULL, 98, 63, '2023-11-04', '2023-11-07', 5, NULL, 15, NULL),
		(NULL, 51, 20, '2023-06-17', '2023-06-20', 3, NULL, 14, NULL),
		(NULL, 8, 57, '2024-01-06', '2024-01-09', 4, NULL, 15, NULL),
		(NULL, 74, 29, '2023-05-20', '2023-05-23', 5, NULL, 7, NULL),
		(NULL, 35, 69, '2023-10-04', '2023-10-07', 3, NULL, 16, NULL),
		(NULL, 87, 72, '2023-11-23', '2023-11-26', 4, NULL, 6, NULL),
		(NULL, 30, 5, '2023-03-23', '2023-03-26', 3, NULL, 14, NULL),
		(NULL, 91, 14, '2023-05-30', '2023-06-02', 8, NULL, 3, NULL),
		(NULL, 46, 17, '2023-08-16', '2023-08-19', 2, NULL, 15, NULL),
		(NULL, 62, 33, '2023-09-08', '2023-09-11', 4, NULL, 14, NULL),
		(NULL, 11, 51, '2024-02-29', '2024-03-03', 5, NULL, 15, NULL),
		(NULL, 85, 10, '2023-07-22', '2023-07-25', 3, NULL, 7, NULL),
		(NULL, 40, 41, '2023-11-27', '2023-11-30', 5, NULL, 14, NULL),
		(NULL, 68, 46, '2023-05-03', '2023-05-06', 3, NULL, 6, NULL),
		(NULL, 16, 70, '2023-10-12', '2023-10-15', 5, NULL, 15, NULL),
		(NULL, 96, 39, '2023-12-29', '2023-12-31', 4, NULL, 3, NULL),
		(NULL, 53, 50, '2024-02-18', '2024-02-21', 3, NULL, 16, NULL),
		(NULL, 2, 55, '2024-03-10', '2024-03-13', 8, NULL, 15, NULL),
		(NULL, 79, 61, '2023-12-07', '2023-12-10', 3, NULL, 7, NULL),
		(NULL, 25, 28, '2023-06-24', '2023-06-27', 4, NULL, 14, NULL),
		(NULL, 82, 24, '2023-04-14', '2023-04-17', 3, NULL, 6, NULL),
		(NULL, 59, 35, '2023-09-22', '2023-09-25', 5, NULL, 15, NULL),
		(NULL, 18, 73, '2024-02-25', '2024-02-28', 3, NULL, 14, NULL),
		(NULL, 94, 66, '2024-01-19', '2024-01-22', 4, NULL, 3, NULL),
		(NULL, 43, 25, '2023-03-13', '2023-03-16', 3, NULL, 16, NULL),
		(NULL, 67, 68, '2023-11-14', '2023-11-17', 5, NULL, 15, NULL),
		(NULL, 12, 48, '2023-12-15', '2023-12-18', 3, NULL, 7, NULL),
		(NULL, 77, 27, '2023-04-02', '2023-04-05', 8, NULL, 14, NULL),
		(NULL, 32, 56, '2023-07-13', '2023-07-16', 3, NULL, 6, NULL),
		(NULL, 89, 62, '2024-01-13', '2024-01-16', 4, NULL, 15, NULL),
		(NULL, 56, 11, '2023-02-10', '2023-02-13', 3, NULL, 14, NULL),
		(NULL, 21, 53, '2023-09-29', '2023-10-02', 5, NULL, 3, NULL),
		(NULL, 72, 72, '2023-11-26', '2023-11-29', 3, NULL, 16, NULL),
		(NULL, 37, 36, '2023-12-01', '2023-12-04', 2, NULL, 15, NULL),
		(NULL, 97, 6, '2023-02-13', '2023-02-16', 3, NULL, 7, NULL),
		(NULL, 50, 19, '2023-06-10', '2023-06-13', 4, NULL, 14, NULL),
		(NULL, 4, 43, '2023-11-03', '2023-11-06', 5, NULL, 15, NULL),
		(NULL, 61, 16, '2023-07-31', '2023-08-03', 3, NULL, 3, NULL),
		(NULL, 28, 31, '2023-10-07', '2023-10-10', 8, NULL, 14, NULL),
		(NULL, 84, 59, '2024-02-12', '2024-02-15', 3, NULL, 6, NULL),
		(NULL, 47, 64, '2023-01-27', '2023-01-30', 5, NULL, 15, NULL),
		(NULL, 64, 38, '2023-12-22', '2023-12-25', 3, NULL, 7, NULL),
		(NULL, 19, 71, '2023-10-20', '2023-10-23', 5, NULL, 14, NULL),
		(NULL, 75, 34, '2023-11-06', '2023-11-09', 3, NULL, 15, NULL),
		(NULL, 41, 67, '2023-06-27', '2023-06-30', 4, NULL, 3, NULL),
		(NULL, 86, 12, '2023-02-20', '2023-02-23', 3, NULL, 16, NULL),
		(NULL, 33, 42, '2023-09-15', '2023-09-18', 8, NULL, 15, NULL),
		(NULL, 92, 60, '2023-08-13', '2023-08-16', 3, NULL, 14, NULL),
		(NULL, 57, 21, '2023-04-16', '2023-04-19', 5, NULL, 6, NULL),
		(NULL, 26, 23, '2023-04-10', '2023-04-13', 3, NULL, 15, NULL),
		(NULL, 81, 74, '2023-11-30', '2023-12-03', 4, NULL, 7, NULL),
		(NULL, 58, 26, '2023-04-26', '2023-04-29', 3, NULL, 16, NULL),
		(NULL, 31, 30, '2023-07-31', '2023-08-03', 5, NULL, 15, NULL),
		(NULL, 14, 58, '2023-06-27', '2023-06-30', 3, NULL, 14, NULL),
		(NULL, 73, 14, '2023-05-30', '2023-06-02', 8, NULL, 15, NULL),
		(NULL, 9, 22, '2023-04-21', '2023-04-24', 3, NULL, 6, NULL),
		(NULL, 54, 12, '2023-02-20', '2023-02-23', 3, NULL, 15, NULL),
		(NULL, 20, 68, '2023-11-14', '2023-11-17', 5, NULL, 7, NULL),
		(NULL, 76, 63, '2023-11-04', '2023-11-07', 5, NULL, 15, NULL),
		(NULL, 34, 35, '2023-09-22', '2023-09-25', 5, NULL, 16, NULL),
		(NULL, 88, 74, '2023-11-30', '2023-12-03', 4, NULL, 3, NULL),
		(NULL, 45, 40, '2023-11-27', '2023-11-30', 5, NULL, 15, NULL),
		(NULL, 63, 24, '2023-04-14', '2023-04-17', 3, NULL, 14, NULL),
		(NULL, 10, 42, '2023-09-15', '2023-09-18', 8, NULL, 15, NULL),
		(NULL, 78, 67, '2023-06-27', '2023-06-30', 4, NULL, 3, NULL),
		(NULL, 27, 41, '2023-11-27', '2023-11-30', 5, NULL, 16, NULL),
		(NULL, 83, 26, '2023-04-26', '2023-04-29', 3, NULL, 15, NULL),
		(NULL, 60, 32, '2023-10-07', '2023-10-10', 8, NULL, 14, NULL),
		(NULL, 15, 38, '2023-12-22', '2023-12-25', 3, NULL, 7, NULL),
		(NULL, 44, 72, '2023-11-26', '2023-11-29', 3, NULL, 16, NULL),
		(NULL, 69, 20, '2023-06-17', '2023-06-20', 3, NULL, 15, NULL),
		(NULL, 5, 57, '2024-01-06', '2024-01-09', 4, NULL, 14, NULL),
		(NULL, 71, 36, '2023-12-01', '2023-12-04', 2, NULL, 3, NULL),
		(NULL, 36, 55, '2024-03-10', '2024-03-13', 8, NULL, 15, NULL),
		(NULL, 93, 30, '2023-07-31', '2023-08-03', 5, NULL, 14, NULL),
		(NULL, 52, 39, '2023-12-29', '2023-12-31', 4, NULL, 6, NULL),
		(NULL, 7, 64, '2023-01-27', '2023-01-30', 5, NULL, 15, NULL),
		(NULL, 65, 50, '2024-02-18', '2024-02-21', 3, NULL, 7, NULL),
		(NULL, 24, 53, '2023-09-29', '2023-10-02', 5, NULL, 16, NULL),
		(NULL, 80, 70, '2023-10-12', '2023-10-15', 5, NULL, 15, NULL),
		(NULL, 49, 18, '2023-06-10', '2023-06-13', 4, NULL, 3, NULL),
		(NULL, 95, 25, '2023-03-13', '2023-03-16', 3, NULL, 14, NULL),
		(NULL, 42, 19, '2023-06-10', '2023-06-13', 4, NULL, 6, NULL),
		(NULL, 70, 62, '2024-01-13', '2024-01-16', 4, NULL, 15, NULL),
		(NULL, 3, 54, '2023-09-08', '2023-09-11', 4, NULL, 14, NULL),
		(NULL, 66, 33, '2023-09-08', '2023-09-11', 4, NULL, 3, NULL),
		(NULL, 23, 46, '2023-05-03', '2023-05-06', 3, NULL, 16, NULL),
		(NULL, 90, 71, '2023-10-20', '2023-10-23', 5, NULL, 15, NULL),
		(NULL, 48, 37, '2023-12-01', '2023-12-04', 2, NULL, 14, NULL),
		(NULL, 6, 47, '2023-08-16', '2023-08-19', 2, NULL, 6, NULL),
		(NULL, 77, 27, '2023-05-03', '2023-05-06', 3, NULL, 15, NULL),
		(NULL, 32, 56, '2023-12-15', '2023-12-18', 3, NULL, 16, NULL),
		(NULL, 87, 11, '2023-03-27', '2023-03-30', 5, NULL, 3, NULL),
		(NULL, 59, 31, '2023-08-06', '2023-08-09', 2, NULL, 14, NULL),
		(NULL, 25, 66, '2024-02-06', '2024-02-09', 5, NULL, 15, NULL),
		(NULL, 82, 29, '2023-06-24', '2023-06-27', 3, NULL, 6, NULL),
		(NULL, 47, 28, '2023-06-03', '2023-06-06', 5, NULL, 15, NULL),
		(NULL, 94, 51, '2024-03-16', '2024-03-19', 3, NULL, 7, NULL),
		(NULL, 51, 59, '2023-12-08', '2023-12-11', 3, NULL, 15, NULL),
		(NULL, 16, 69, '2023-11-24', '2023-11-27', 4, NULL, 3, NULL),
		(NULL, 75, 45, '2024-03-29', '2024-04-01', 5, NULL, 16, NULL),
		(NULL, 39, 17, '2023-05-27', '2023-05-30', 5, NULL, 15, NULL),
		(NULL, 91, 48, '2023-06-17', '2023-06-20', 3, NULL, 14, NULL),
		(NULL, 50, 44, '2023-08-20', '2023-08-23', 3, NULL, 6, NULL),
		(NULL, 17, 43, '2023-08-27', '2023-08-30', 5, NULL, 15, NULL),
		(NULL, 72, 65, '2024-01-20', '2024-01-23', 4, NULL, 16, NULL),
		(NULL, 37, 61, '2023-12-22', '2023-12-25', 3, NULL, 15, NULL),
		(NULL, 89, 34, '2023-09-01', '2023-09-04', 4, NULL, 7, NULL),
		(NULL, 46, 49, '2024-03-29', '2024-04-01', 5, NULL, 15, NULL),
		(NULL, 67, 52, '2023-09-15', '2023-09-18', 8, NULL, 14, NULL),
		(NULL, 84, 73, '2024-02-23', '2024-02-26', 3, NULL, 15, NULL),
		(NULL, 38, 60, '2023-05-20', '2023-05-23', 5, NULL, 16, NULL),
		(NULL, 92, 15, '2023-09-29', '2023-10-02', 5, NULL, 15, NULL),
		(NULL, 55, 21, '2023-12-08', '2023-12-11', 3, NULL, 7, NULL),
		(NULL, 2, 8, '2023-09-08', '2023-09-11', 4, NULL, 14, NULL),
		(NULL, 68, 23, '2023-05-20', '2023-05-23', 5, NULL, 3, NULL),
		(NULL, 31, 75, '2024-03-22', '2024-03-25', 5, NULL, 15, NULL),
		(NULL, 86, 10, '2023-08-03', '2023-08-06', 3, NULL, 16, NULL),
		(NULL, 58, 16, '2023-10-30', '2023-11-02', 5, NULL, 15, NULL),
		(NULL, 21, 29, '2024-01-06', '2024-01-09', 4, NULL, 6, NULL),
		(NULL, 74, 41, '2023-04-10', '2023-04-13', 3, NULL, 15, NULL),
		(NULL, 35, 2, '2023-06-17', '2023-06-20', 3, NULL, 14, NULL),
		(NULL, 89, 70, '2023-05-17', '2023-05-20', 4, NULL, 3, NULL),
		(NULL, 40, 54, '2023-05-03', '2023-05-06', 5, NULL, 16, NULL),
		(NULL, 3, 33, '2023-07-31', '2023-08-03', 5, NULL, 15, NULL),
		(NULL, 77, 57, '2023-05-10', '2023-05-13', 3, NULL, 7, NULL),
		(NULL, 32, 39, '2023-06-17', '2023-06-20', 3, NULL, 14, NULL),
		(NULL, 78, 47, '2023-05-24', '2023-05-27', 5, NULL, 6, NULL),
		(NULL, 12, 9, '2023-11-03', '2023-11-06', 5, NULL, 15, NULL),
		(NULL, 66, 64, '2024-02-13', '2024-02-16', 4, NULL, 3, NULL),
		(NULL, 43, 32, '2023-04-28', '2023-05-01', 5, NULL, 16, NULL),
		(NULL, 88, 71, '2023-09-15', '2023-09-18', 8, NULL, 15, NULL),
		(NULL, 14, 38, '2023-06-03', '2023-06-06', 5, NULL, 14, NULL),
		(NULL, 61, 50, '2024-01-13', '2024-01-16', 4, NULL, 6, NULL),
		(NULL, 36, 34, '2023-10-24', '2023-10-27', 3, NULL, 15, NULL),
		(NULL, 82, 27, '2023-12-08', '2023-12-11', 3, NULL, 16, NULL),
		(NULL, 22, 72, '2023-09-29', '2023-10-02', 5, NULL, 15, NULL),
		(NULL, 76, 8, '2023-06-10', '2023-06-13', 4, NULL, 3, NULL),
		(NULL, 50, 65, '2023-08-17', '2023-08-20', 5, NULL, 14, NULL),
		(NULL, 28, 30, '2023-05-13', '2023-05-16', 3, NULL, 7, NULL),
		(NULL, 83, 46, '2023-03-31', '2023-04-03', 5, NULL, 15, NULL),
		(NULL, 17, 19, '2023-04-17', '2023-04-20', 3, NULL, 16, NULL),
		(NULL, 71, 61, '2023-09-22', '2023-09-25', 5, NULL, 15, NULL),
		(NULL, 42, 55, '2024-01-06', '2024-01-09', 4, NULL, 6, NULL),
		(NULL, 87, 74, '2023-08-17', '2023-08-20', 5, NULL, 15, NULL),
		(NULL, 9, 56, '2023-07-07', '2023-07-10', 3, NULL, 16, NULL),
		(NULL, 65, 59, '2023-09-01', '2023-09-04', 4, NULL, 15, NULL),
		(NULL, 34, 22, '2023-09-08', '2023-09-11', 4, NULL, 7, NULL),
		(NULL, 80, 62, '2023-07-28', '2023-07-31', 5, NULL, 15, NULL),
		(NULL, 5, 42, '2023-09-08', '2023-09-11', 4, NULL, 16, NULL),
		(NULL, 81, 63, '2023-07-14', '2023-07-17', 5, NULL, 3, NULL),
		(NULL, 54, 13, '2023-07-17', '2023-07-20', 3, NULL, 14, NULL),
		(NULL, 29, 37, '2023-07-28', '2023-07-31', 5, NULL, 15, NULL),
		(NULL, 90, 58, '2023-12-29', '2024-01-01', 3, NULL, 6, NULL),
		(NULL, 18, 40, '2023-05-03', '2023-05-06', 5, NULL, 15, NULL),
		(NULL, 79, 24, '2023-06-03', '2023-06-06', 5, NULL, 16, NULL),
		(NULL, 10, 5, '2023-04-20', '2023-04-23', 3, NULL, 15, NULL),
		(NULL, 70, 67, '2024-01-20', '2024-01-23', 4, NULL, 7, NULL),
		(NULL, 41, 53, '2023-09-22', '2023-09-25', 5, NULL, 15, NULL),
		(NULL, 48, 12, '2023-07-07', '2023-07-10', 3, NULL, 16, NULL),
		(NULL, 73, 18, '2023-09-08', '2023-09-11', 4, NULL, 3, NULL),
		(NULL, 19, 52, '2023-06-10', '2023-06-13', 4, NULL, 15, NULL),
		(NULL, 64, 49, '2023-06-17', '2023-06-20', 3, NULL, 7, NULL),
		(NULL, 33, 31, '2023-06-24', '2023-06-27', 3, NULL, 16, NULL),
		(NULL, 85, 28, '2023-06-03', '2023-06-06', 5, NULL, 15, NULL),
		(NULL, 15, 68, '2023-09-22', '2023-09-25', 5, NULL, 6, NULL),
		(NULL, 60, 11, '2023-05-27', '2023-05-30', 4, NULL, 3, NULL),
		(NULL, 37, 43, '2023-09-22', '2023-09-25', 5, NULL, 15, NULL),
		(NULL, 91, 36, '2023-08-10', '2023-08-13', 4, NULL, 16, NULL),
		(NULL, 11, 48, '2023-11-10', '2023-11-13', 5, NULL, 3, NULL),
		(NULL, 69, 66, '2023-07-14', '2023-07-17', 5, NULL, 15, NULL),
		(NULL, 44, 44, '2023-05-03', '2023-05-06', 5, NULL, 7, NULL),
		(NULL, 93, 35, '2023-09-01', '2023-09-04', 4, NULL, 16, NULL),
		(NULL, 24, 6, '2023-09-15', '2023-09-18', 5, NULL, 15, NULL),
		(NULL, 67, 3, '2023-07-28', '2023-07-31', 5, NULL, 3, NULL),
		(NULL, 39, 17, '2023-08-24', '2023-08-27', 3, NULL, 15, NULL),
		(NULL, 94, 26, '2023-06-10', '2023-06-13', 4, NULL, 6, NULL),
		(NULL, 13, 51, '2023-05-13', '2023-05-16', 3, NULL, 15, NULL),
		(NULL, 62, 45, '2023-12-01', '2023-12-04', 5, NULL, 7, NULL),
		(NULL, 46, 20, '2023-06-03', '2023-06-06', 5, NULL, 16, NULL),
		(NULL, 95, 69, '2023-11-10', '2023-11-13', 5, NULL, 15, NULL),
		(NULL, 23, 14, '2023-07-28', '2023-07-31', 5, NULL, 3, NULL),
		(NULL, 63, 4, '2023-06-03', '2023-06-06', 5, NULL, 15, NULL),
		(NULL, 45, 25, '2023-09-15', '2023-09-18', 5, NULL, 16, NULL),
		(NULL, 96, 1, '2023-06-17', '2023-06-20', 3, NULL, 15, NULL),
		(NULL, 25, 7, '2023-08-10', '2023-08-13', 4, NULL, 7, NULL),
		(NULL, 72, 56, '2023-08-03', '2023-08-06', 3, NULL, 16, NULL),
		(NULL, 47, 65, '2023-07-31', '2023-08-03', 5, NULL, 15, NULL),
		(NULL, 97, 10, '2023-06-24', '2023-06-27', 3, NULL, 3, NULL),
		(NULL, 16, 27, '2023-06-17', '2023-06-20', 3, NULL, 15, NULL),
		(NULL, 59, 53, '2023-08-24', '2023-08-27', 3, NULL, 16, NULL),
		(NULL, 26, 70, '2023-06-10', '2023-06-13', 4, NULL, 15, NULL),
		(NULL, 98, 19, '2023-05-20', '2023-05-23', 5, NULL, 6, NULL),
		(NULL, 27, 57, '2023-08-17', '2023-08-20', 5, NULL, 15, NULL),
		(NULL, 75, 42, '2023-06-24', '2023-06-27', 3, NULL, 3, NULL),
		(NULL, 49, 33, '2023-06-03', '2023-06-06', 5, NULL, 15, NULL),
		(NULL, 99, 60, '2023-09-15', '2023-09-18', 5, NULL, 7, NULL),
		(NULL, 30, 21, '2023-08-10', '2023-08-13', 4, NULL, 16, NULL),
		(NULL, 100, 64, '2023-09-22', '2023-09-25', 5, NULL, 15, NULL),
		(NULL, 51, 38, '2023-06-17', '2023-06-20', 3, NULL, 3, NULL),
		(NULL, 74, 61, '2023-05-03', '2023-05-06', 5, NULL, 15, NULL),
		(NULL, 38, 55, '2023-08-17', '2023-08-20', 5, NULL, 16, NULL),
		(NULL, 101, 47, '2023-06-03', '2023-06-06', 5, NULL, 7, NULL),
		(NULL, 31, 32, '2023-09-08', '2023-09-11', 4, NULL, 16, NULL),
		(NULL, 102, 8, '2023-06-17', '2023-06-20', 3, NULL, 15, NULL),
		(NULL, 32, 39, '2023-08-03', '2023-08-06', 3, NULL, 3, NULL),
		(NULL, 103, 15, '2023-06-24', '2023-06-27', 3, NULL, 15, NULL),
		(NULL, 53, 71, '2023-07-28', '2023-07-31', 5, NULL, 16, NULL),
		(NULL, 104, 29, '2023-08-17', '2023-08-20', 5, NULL, 6, NULL),
		(NULL, 35, 50, '2023-09-01', '2023-09-04', 4, NULL, 15, NULL),
		(NULL, 105, 46, '2023-08-10', '2023-08-13', 4, NULL, 7, NULL),
		(NULL, 36, 54, '2023-06-24', '2023-06-27', 3, NULL, 16, NULL);
        

INSERT INTO pago_proveedores(id_payment_transaction, id_sale_transaction, sale_trx_value, commission_agreed, total_payment)
VALUES (null,1, null, null, null),
	   (null,2, null, null, null),
	   (null,3, null, null, null),
	   (null,4, null, null, null),
	   (null,5, null, null, null),
	   (null,6, null, null, null),
	   (null,7, null, null, null),
	   (null,8, null, null, null),
	   (null,9, null, null, null),
	   (null,10, null, null, null),
	   (null,11, null, null, null),
	   (null,12, null, null, null),
	   (null,13, null, null, null),
	   (null,14, null, null, null),
	   (null,15, null, null, null),
	   (null,16, null, null, null),
	   (null,17, null, null, null),
	   (null,18, null, null, null),
	   (null,19, null, null, null),
	   (null,20, null, null, null),
	   (null,21, null, null, null),
	   (null,22, null, null, null),
	   (null,23, null, null, null),
	   (null,24, null, null, null),
	   (null,25, null, null, null),
	   (null,26, null, null, null),
	   (null,27, null, null, null),
	   (null,28, null, null, null),
	   (null,29, null, null, null),
	   (null,30, null, null, null),
	   (null,31, null, null, null),
	   (null,32, null, null, null),
	   (null,33, null, null, null),
	   (null,34, null, null, null),
	   (null,35, null, null, null),
	   (null,36, null, null, null),
	   (null,37, null, null, null),
	   (null,38, null, null, null),
	   (null,39, null, null, null),
	   (null,40, null, null, null),
	   (null,41, null, null, null),
	   (null,42, null, null, null),
	   (null,43, null, null, null),
	   (null,44, null, null, null),
	   (null,45, null, null, null),
	   (null,46, null, null, null),
	   (null,47, null, null, null),
	   (null,48, null, null, null),
	   (null,49, null, null, null),
	   (null,50, null, null, null),
	   (null,51, null, null, null),
	   (null,52, null, null, null),
	   (null,53, null, null, null),
	   (null,54, null, null, null),
	   (null,55, null, null, null),
	   (null,56, null, null, null),
	   (null,57, null, null, null),
	   (null,58, null, null, null),
	   (null,59, null, null, null),
	   (null,60, null, null, null),
	   (null,61, null, null, null),
	   (null,62, null, null, null),
	   (null,63, null, null, null),
	   (null,64, null, null, null),
	   (null,65, null, null, null),
	   (null,66, null, null, null),
	   (null,67, null, null, null),
	   (null,68, null, null, null),
	   (null,69, null, null, null),
	   (null,70, null, null, null),
	   (null,71, null, null, null),
	   (null,72, null, null, null),
	   (null,73, null, null, null),
	   (null,74, null, null, null),
	   (null,75, null, null, null),
	   (null,76, null, null, null),
	   (null,77, null, null, null),
	   (null,78, null, null, null),
	   (null,79, null, null, null),
	   (null,80, null, null, null),
	   (null,81, null, null, null),
	   (null,82, null, null, null),
	   (null,83, null, null, null),
	   (null,84, null, null, null),
	   (null,85, null, null, null),
	   (null,86, null, null, null),
	   (null,87, null, null, null),
	   (null,88, null, null, null),
	   (null,89, null, null, null),
	   (null,90, null, null, null),
	   (null,91, null, null, null),
	   (null,92, null, null, null),
	   (null,93, null, null, null),
	   (null,94, null, null, null),
	   (null,95, null, null, null),
	   (null,96, null, null, null),
	   (null,97, null, null, null),
	   (null,98, null, null, null),
	   (null,99, null, null, null),
	   (null,100, null, null, null),
	   (null,101, null, null, null),
	   (null,102, null, null, null),
	   (null,103, null, null, null),
	   (null,104, null, null, null),
	   (null,105, null, null, null),
	   (null,106, null, null, null),
	   (null,107, null, null, null),
	   (null,108, null, null, null),
	   (null,109, null, null, null),
	   (null,110, null, null, null),
	   (null,111, null, null, null),
	   (null,112, null, null, null),
	   (null,113, null, null, null),
	   (null,114, null, null, null),
	   (null,115, null, null, null),
	   (null,116, null, null, null),
	   (null,117, null, null, null),
	   (null,118, null, null, null),
	   (null,119, null, null, null),
	   (null,120, null, null, null),
	   (null,121, null, null, null),
	   (null,122, null, null, null),
	   (null,123, null, null, null),
	   (null,124, null, null, null),
	   (null,125, null, null, null),
	   (null,126, null, null, null),
	   (null,127, null, null, null),
	   (null,128, null, null, null),
	   (null,129, null, null, null),
	   (null,130, null, null, null),
	   (null,131, null, null, null),
	   (null,132, null, null, null),
	   (null,133, null, null, null),
	   (null,134, null, null, null),
	   (null,135, null, null, null),
	   (null,136, null, null, null),
	   (null,137, null, null, null),
	   (null,138, null, null, null),
	   (null,139, null, null, null),
	   (null,140, null, null, null),
	   (null,141, null, null, null),
	   (null,142, null, null, null),
	   (null,143, null, null, null),
	   (null,144, null, null, null),
	   (null,145, null, null, null),
	   (null,146, null, null, null),
	   (null,147, null, null, null),
	   (null,148, null, null, null),
	   (null,149, null, null, null),
	   (null,150, null, null, null),
	   (null,151, null, null, null),
	   (null,152, null, null, null),
	   (null,153, null, null, null),
	   (null,154, null, null, null),
	   (null,155, null, null, null),
	   (null,156, null, null, null),
	   (null,157, null, null, null),
	   (null,158, null, null, null),
	   (null,159, null, null, null),
	   (null,160, null, null, null),
	   (null,161, null, null, null),
	   (null,162, null, null, null),
	   (null,163, null, null, null),
	   (null,164, null, null, null),
	   (null,165, null, null, null),
	   (null,166, null, null, null),
	   (null,167, null, null, null),
	   (null,168, null, null, null),
	   (null,169, null, null, null),
	   (null,170, null, null, null),
	   (null,171, null, null, null),
	   (null,172, null, null, null),
	   (null,173, null, null, null),
	   (null,174, null, null, null),
	   (null,175, null, null, null),
	   (null,176, null, null, null),
	   (null,177, null, null, null),
	   (null,178, null, null, null),
	   (null,179, null, null, null),
	   (null,180, null, null, null),
	   (null,181, null, null, null),
	   (null,182, null, null, null),
	   (null,183, null, null, null),
	   (null,184, null, null, null),
	   (null,185, null, null, null),
	   (null,186, null, null, null),
	   (null,187, null, null, null),
	   (null,188, null, null, null),
	   (null,189, null, null, null),
	   (null,190, null, null, null),
	   (null,191, null, null, null),
	   (null,192, null, null, null),
	   (null,193, null, null, null),
	   (null,194, null, null, null),
	   (null,195, null, null, null),
	   (null,196, null, null, null),
	   (null,197, null, null, null),
	   (null,198, null, null, null),
	   (null,199, null, null, null),
	   (null,200, null, null, null),
	   (null,201, null, null, null),
	   (null,202, null, null, null),
	   (null,203, null, null, null),
	   (null,204, null, null, null),
	   (null,205, null, null, null),
	   (null,206, null, null, null),
	   (null,207, null, null, null),
	   (null,208, null, null, null),
	   (null,209, null, null, null),
	   (null,210, null, null, null),
	   (null,211, null, null, null),
	   (null,212, null, null, null),
	   (null,213, null, null, null),
	   (null,214, null, null, null),
	   (null,215, null, null, null),
	   (null,216, null, null, null),
	   (null,217, null, null, null),
	   (null,218, null, null, null),
	   (null,219, null, null, null),
	   (null,220, null, null, null),
	   (null,221, null, null, null),
	   (null,222, null, null, null),
	   (null,223, null, null, null),
	   (null,224, null, null, null),
	   (null,225, null, null, null),
	   (null,226, null, null, null),
	   (null,227, null, null, null),
	   (null,228, null, null, null),
	   (null,229, null, null, null),
	   (null,230, null, null, null),
	   (null,231, null, null, null),
	   (null,232, null, null, null),
	   (null,233, null, null, null),
	   (null,234, null, null, null),
	   (null,235, null, null, null),
	   (null,236, null, null, null),
	   (null,237, null, null, null),
	   (null,238, null, null, null),
	   (null,239, null, null, null),
	   (null,240, null, null, null),
	   (null,241, null, null, null),
	   (null,242, null, null, null),
	   (null,243, null, null, null),
	   (null,244, null, null, null),
	   (null,245, null, null, null),
	   (null,246, null, null, null),
	   (null,247, null, null, null),
	   (null,248, null, null, null),
	   (null,249, null, null, null),
	   (null,250, null, null, null),
	   (null,251, null, null, null),
	   (null,252, null, null, null),
	   (null,253, null, null, null),
	   (null,254, null, null, null),
	   (null,255, null, null, null),
	   (null,256, null, null, null),
	   (null,257, null, null, null),
	   (null,258, null, null, null),
	   (null,259, null, null, null),
	   (null,260, null, null, null),
	   (null,261, null, null, null),
	   (null,262, null, null, null),
	   (null,263, null, null, null),
	   (null,264, null, null, null),
	   (null,265, null, null, null),
	   (null,266, null, null, null),
	   (null,267, null, null, null),
	   (null,268, null, null, null),
	   (null,269, null, null, null),
	   (null,270, null, null, null),
	   (null,271, null, null, null),
	   (null,272, null, null, null),
	   (null,273, null, null, null),
	   (null,274, null, null, null),
	   (null,275, null, null, null),
	   (null,276, null, null, null),
	   (null,277, null, null, null),
	   (null,278, null, null, null),
	   (null,279, null, null, null),
	   (null,280, null, null, null),
	   (null,281, null, null, null),
	   (null,282, null, null, null),
	   (null,283, null, null, null),
	   (null,284, null, null, null),
	   (null,285, null, null, null),
	   (null,286, null, null, null),
	   (null,287, null, null, null),
	   (null,288, null, null, null),
	   (null,289, null, null, null),
	   (null,290, null, null, null),
	   (null,291, null, null, null),
	   (null,292, null, null, null),
	   (null,293, null, null, null),
	   (null,294, null, null, null),
	   (null,295, null, null, null),
	   (null,296, null, null, null),
	   (null,297, null, null, null),
	   (null,298, null, null, null),
	   (null,299, null, null, null),
	   (null,300, null, null, null),
	   (null,301, null, null, null),
	   (null,302, null, null, null),
	   (null,303, null, null, null);

        
INSERT INTO feedback(id_feedback, id_customer, id_experience, feedback_received, feedback_status, resolution)
VALUES  (NULL, 59, 53, 'debieron avisar que haria tanto calor el agua no fue suficiente y la pasamos mal', 2, 'Se otorgó un cupon de descuento para la siguiente experiencia al cliente'),
		(NULL, 97, 36, 'La caminata fue demasiado difícil para el equipo y deberían haberlo revelado antes', 2, 'Se otorgó un cupón de descuento al cliente para la próxima experiencia'),
		(NULL, 14, 12, 'El clima era malo y no pudimos vivir la experiencia completa', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 71, 68, 'Me encantó, pero apreciaría tener opciones para una persona en silla de ruedas', 2, 'Se otorgó un tour gratuito para la siguiente experiencia al cliente'),
		(NULL, 36, 39, 'No había suficiente agua y lo pasamos mal', 1, 'Pendiente en revisión'),
		(NULL, 63, 58, 'El guía turístico era poco informativo y no nos proporcionó suficiente información', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 5, 16, 'El senderismo fue agotador y no disfrutamos la experiencia', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 28, 42, 'Hubo una falta de organización y nos sentimos perdidos durante el recorrido', 2, 'Se otorgó un cupón de descuento al cliente para la próxima experiencia'),
		(NULL, 80, 75, 'La comida proporcionada no era satisfactoria y nos decepcionó', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 51, 26, 'El transporte no llegó a tiempo y llegamos tarde al inicio de la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 19, 10, 'El alojamiento proporcionado no cumplió con nuestras expectativas', 1, 'Pendiente en revisión'),
		(NULL, 94, 47, 'Hubo una falta de comunicación y nos perdimos una parte importante de la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 40, 28, 'El recorrido fue demasiado corto y no valió la pena el costo', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 17, 67, 'Los insectos eran molestos y arruinaron nuestra experiencia al aire libre', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 75, 20, 'No había suficiente equipo de seguridad y nos sentimos inseguros durante la actividad', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 2, 51, 'La experiencia fue maravillosa y nos encantaría volver', 2, 'Se otorgó un pequeño obsequio al cliente como agradecimiento'),
		(NULL, 68, 22, 'No se cumplieron las expectativas y esperábamos más de la experiencia', 1, 'Pendiente en revisión'),
		(NULL, 42, 38, 'El servicio al cliente fue deficiente y no nos sentimos bienvenidos', 2, 'Se otorgó un cupón de descuento al cliente para la próxima experiencia'),
		(NULL, 89, 61, 'Hubo una falta de actividades y nos aburrimos durante la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 16, 13, 'La excursión fue cancelada en el último minuto y nos decepcionó', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 59, 70, 'No hubo suficiente información proporcionada antes del viaje y nos sentimos desprevenidos', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 103, 60, 'El equipo de guías no era profesional y nos sentimos inseguros durante la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 27, 17, 'La experiencia fue genial y nos divertimos mucho', 2, 'Se otorgó un pequeño obsequio al cliente como agradecimiento'),
		(NULL, 13, 51, 'Hubo una falta de comunicación y nos sentimos perdidos durante el recorrido', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 62, 45, 'No había suficiente comida y nos quedamos con hambre', 1, 'Pendiente en revisión'),
		(NULL, 46, 20, 'El equipo de excursionismo proporcionado era de mala calidad y se rompió', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 95, 69, 'La experiencia fue cancelada sin previo aviso y nos sentimos decepcionados', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 23, 14, 'No había suficiente agua y pasamos sed durante la actividad', 1, 'Pendiente en revisión'),
		(NULL, 63, 4, 'El transporte proporcionado no llegó a tiempo y perdimos parte de la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 45, 25, 'El alojamiento proporcionado no era satisfactorio y no pudimos descansar bien', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 96, 1, 'Hubo una falta de actividades emocionantes y nos aburrimos durante la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 25, 7, 'El guía turístico era poco informativo y no nos proporcionó suficiente información', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 72, 56, 'La actividad de rappel era demasiado desafiante y nos sentimos inseguros', 1, 'Pendiente en revisión'),
		(NULL, 47, 65, 'La comida proporcionada no era satisfactoria y nos sentimos decepcionados', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 97, 10, 'El clima era malo y no pudimos vivir la experiencia completa', 2, 'Se otorgó un reembolso parcial al cliente'),
		(NULL, 16, 27, 'El servicio al cliente fue deficiente y no nos sentimos bienvenidos', 2, 'Se otorgó un cupón de descuento al cliente para la próxima experiencia'),
		(NULL, 59, 53, 'No hubo suficiente información proporcionada antes del viaje y nos sentimos desprevenidos', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 26, 70, 'La caminata fue demasiado difícil para el equipo y deberían haberlo revelado antes', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 98, 19, 'El clima era malo y no pudimos vivir la experiencia completa', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 27, 57, 'No había suficiente agua y lo pasamos mal', 1, 'Pendiente en revisión'),
		(NULL, 49, 33, 'Hubo una falta de organización y nos sentimos perdidos durante el recorrido', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 99, 60, 'El senderismo fue agotador y no disfrutamos la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 30, 21, 'El transporte no llegó a tiempo y llegamos tarde al inicio de la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias'),
		(NULL, 100, 64, 'El equipo de guías no era profesional y nos sentimos inseguros durante la experiencia', 2, 'Se otorgaron cupones de descuento al cliente para futuras experiencias');
        



-- ------------------------------------------------------- Function Creation Scripts ----------------------------------------------------------------------
-- -- ---------- Función para calcular precio de venta por grupo
DROP FUNCTION IF EXISTS f_precio_venta_grupo
DELIMITER && 
CREATE FUNCTION f_precio_venta_grupo(param_number_of_people INT, param_id_experience INT)
RETURNS DECIMAL (10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE individual_price DECIMAL(10);
    DECLARE total_price DECIMAL(10);
    
    SELECT price_per_person INTO individual_price
    FROM experiencias_tours
    WHERE id_experience = param_id_experience;
    
    SET total_price = individual_price * param_number_of_people;
    
    RETURN total_price;
    
END;
&& 
-- SELECT f_precio_venta_grupo(8,72);

-- -- ---------- Función para calcular transacciones de venta logradas por empleado (exclusivo para area de ventas)
DROP FUNCTION IF EXISTS f_ventas_por_empleado;
DELIMITER %%
CREATE FUNCTION  `f_ventas_por_empleado` (param_id_employee INT)
RETURNS INTEGER DETERMINISTIC
BEGIN
RETURN
	(SELECT count(*)
     FROM ventas AS v
     WHERE v.id_employee_sale = param_id_employee);   
END;
%%
-- SELECT * FROM analisis_salarios;
-- WHERE position_name LIKE '%ven%';
-- SELECT f_ventas_por_empleado(16);



-- -- ---------- Función para calcular el % de bono sobre ventas correspondiente al los empleados (exclusivo para area de ventas)

DROP FUNCTION IF EXISTS f_definir_bono;
DELIMITER $$
CREATE FUNCTION `f_definir_bono`(param_total_sales DECIMAL(10))
RETURNS DECIMAL (10,2)
DETERMINISTIC
BEGIN
	DECLARE bonus DECIMAL (10,2);    
    IF param_total_sales > 400000 THEN
		SET bonus = 0.3;
	ELSEIF param_total_sales BETWEEN 200000 AND 399000 THEN
		SET bonus = 0.2;
	ELSE 
		SET bonus = 0.05;
	END IF;
    
    RETURN bonus;
END;
$$
-- SELECT f_definir_bono(500000);

-- ------------------------------------------------------- Stored Procedure Scripts ----------------------------------------------------------------------

-- Rutina para Asignar bonos anuales a los empleados de venta
DROP PROCEDURE IF EXISTS sp_asignar_bono
DELIMITER ??
CREATE PROCEDURE `sp_asignar_bono`()
BEGIN
	DROP VIEW IF EXISTS ventas_por_empleado;
    CREATE VIEW ventas_por_empleado AS
    SELECT 
	v.id_employee_sale,
    e.employee_name,
    p.position_name,
	sum(v.group_size * ex.price_per_person) AS sale_per_employee
FROM ventas AS v
	INNER JOIN experiencias_tours AS ex ON (v.id_experience = ex.id_experience)
    INNER JOIN empleados AS e ON (e.id_employee = v.id_employee_sale)
    INNER JOIN puestos AS p ON (p.id_position = e.id_position)
GROUP BY 
	v.id_employee_sale
ORDER BY 
	sale_per_employee DESC;
    
DROP VIEW IF EXISTS bono_por_empleado;
CREATE VIEW bono_por_empleado AS
SELECT 
	spe.id_employee_sale,
    spe.employee_name,
    spe.position_name,
	spe.sale_per_employee,
    f_definir_bono(spe.sale_per_employee) AS bonus_percentage,
    f_definir_bono(spe.sale_per_employee) * spe.sale_per_employee AS total_bonus,
    e.salary + (spe.sale_per_employee * f_definir_bono(spe.sale_per_employee)) AS total_payment
FROM ventas_por_empleado AS spe
	INNER JOIN empleados AS e ON (e.id_employee = spe.id_employee_sale);


SELECT * FROM bono_por_empleado;
END;
??
-- CALL sp_asignar_bono()

-- Rutina para Seleccionar Tablas para el director de Ventas (consultas limitadas)
DROP PROCEDURE sp_seleccionar_tabla
DELIMITER !!
CREATE PROCEDURE sp_seleccionar_tabla(param_tabla VARCHAR(20))
BEGIN 
	IF param_tabla = 'ventas' THEN
		SELECT * FROM ventas;
	ELSEIF param_tabla = 'experiencias_tours' THEN
		SELECT * FROM experiencias_tours;
	ELSEIF param_tabla = 'feedback' THEN
		SELECT * FROM feedback;
	ELSE
		SIGNAL sqlstate VALUE '99900'
			SET MESSAGE_TEXT = 'ERROR: No tiene permisos para ver la tabla seleccionada';
	END IF;

END;
!!
-- CALL sp_seleccionar_tabla('ventas')

-- Rutina para Seleccionar Cualquier Tabla del sistema de forma dinamica (consultas abiertas)
DROP PROCEDURE sp_seleccionar_tabla_dir
DELIMITER ¡¡
CREATE PROCEDURE sp_seleccionar_tabla_dir(param_tabla_dir VARCHAR(20))
BEGIN 
	SET @table_requested_dir = CONCAT('SELECT * FROM ', param_tabla_dir);
	
    PREPARE cursor_sql FROM @table_requested_dir;
    EXECUTE cursor_sql;
    DEALLOCATE PREPARE cursor_sql;
    
END;
¡¡
-- CALL sp_seleccionar_tabla_dir('puestos')


-- ------------------------------------------------------- View Creation Scripts ----------------------------------------------------------------------
    
    -- ---------- View de pago a proveedores
-- DROP VIEW IF EXISTS v_pagos_proveedores;
CREATE VIEW v_pagos_proveedores AS
SELECT 
	v.id_sale_transaction,
    v.sale_date, 
    v.group_size, 
    ex.price_per_person, 
    ex.payment_agreement_percent, 
    v.group_size * ex.price_per_person AS sale_value,
    (v.group_size * ex.price_per_person) - ((v.group_size * ex.price_per_person) * (ex.payment_agreement_percent / 100)) AS supplier_payment,
    DATE_ADD(v.sale_date, INTERVAL 20 DAY) AS payment_date
FROM  ventas as V	
INNER JOIN experiencias_tours as ex ON (v.id_experience = ex.id_experience)
ORDER BY payment_date;
-- SELECT * FROM v_pagos_proveedores;

-- ---------- View de Transacciones Por Proveedor 
-- DROP VIEW IF EXISTS v_transacciones_por_proveedor;
CREATE VIEW v_transacciones_por_proveedor AS
SELECT 
	ex.id_supplier, 
	p.company_name,
    COUNT(v.id_sale_transaction) as total_transactions,
	SUM(v.group_size * ex.price_per_person) AS total_sales
FROM ventas AS v
	INNER JOIN experiencias_tours AS ex ON (v.id_experience = ex.id_experience)
    INNER JOIN proveedores_experiencias AS p ON (p.id_supplier = ex.id_supplier)
GROUP BY 
	ex.id_supplier,
    p.company_name
ORDER BY total_sales DESC;
-- SELECT * FROM v_transacciones_por_proveedor;


-- ---------- View de ventas por estado
-- DROP VIEW IF EXISTS v_ventas_por_estado;
CREATE VIEW v_ventas_por_estado AS
SELECT 
	ex.id_location, 
    loc.state, 
    COUNT(v.id_sale_transaction) AS transactions_per_state,
    SUM(v.group_size * ex.price_per_person) AS sales_per_state
FROM ventas AS v
	INNER JOIN experiencias_tours AS ex ON (v.id_experience = ex.id_experience)
	INNER JOIN ubicacion AS loc ON (ex.id_location = loc.id_location)
GROUP BY
	ex.id_location, 
    loc.state
ORDER BY
	sales_per_state DESC;
-- SELECT * FROM v_ventas_por_estado;

-- ---------- View de Top 10 de Experiencias Vendidas
-- DROP VIEW IF EXISTS v_top_sellers_experiencias;
CREATE VIEW v_top_sellers_experiencias AS
SELECT 
	ex.id_experience,
    ex.experience_name, 
    SUM(v.amount_total) AS total_sales
FROM experiencias_tours AS ex
	INNER JOIN ventas AS v ON (v.id_experience = ex.id_experience)
GROUP BY
	ex.id_experience,
    ex.experience_name
ORDER BY
	total_sales DESC
LIMIT 10;
-- SELECT * FROM v_top_sellers_experiencias;

-- -- ---------- View de análisis de nómina y equidad salarial
-- DROP VIEW IF EXISTS v_analisis_salarios;
CREATE VIEW v_analisis_salarios AS
SELECT 
	e.id_employee,
    e.employee_name,
    p.position_name,
    d.department_name,
    r.id_rank,
    r.rank_name_hierarchy,
    e.salary,
    r.salary_floor,
    r.salary_ceiling
FROM empleados AS e
	INNER JOIN puestos as p ON (p.id_position = e.id_position)
    INNER JOIN rangos as r ON (r.id_rank = p.id_rank)
    INNER JOIN departamentos as d ON(p.id_department=d.id_department)
ORDER BY
	salary DESC;
-- SELECT * FROM v_analisis_salarios;

