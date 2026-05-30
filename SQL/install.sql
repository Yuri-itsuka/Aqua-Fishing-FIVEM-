INSERT INTO items (name, label, weight) VALUES
('angel', 'Angel', 1),
('fish', 'Fisch', 1),
('boot', 'Alter Stiefel', 1),
('kondom', 'Kondom', 1),
('angel_update', 'Angel Upgrade', 1);

CREATE TABLE IF NOT EXISTS fishing_stats (
    identifier VARCHAR(60) NOT NULL,
    name VARCHAR(50),
    fish_caught INT DEFAULT 0,
    money_earned INT DEFAULT 0,
    biggest_fish FLOAT DEFAULT 0,
    PRIMARY KEY (identifier)
);
