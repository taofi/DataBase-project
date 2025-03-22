const express = require('express');
const session = require('express-session');
const path = require('path');
const oracledb = require('oracledb');

const app = express();
app.use(express.urlencoded({ extended: true }));
const staticDir = path.join(__dirname, '../static');

let connection;
const dbConfig = {
    user: 'Admin_user',
    password: 'password',
    connectString: 'localhost/coursePDB',
};

// Настройка middleware для сессий
app.use(session({
    secret: 'ashl434AS2daAdaafdSsfaA2DL2',
    resave: false,
    saveUninitialized: true,
    cookie: { maxAge: 50000000 }
}));

// Middleware для обработки JSON
app.use(express.json());

// Функция подключения к базе данных с переподключением
async function connectToDatabase(retries = 5, delay = 5000) {
    for (let attempt = 1; attempt <= retries; attempt++) {
        try {
            console.log(`Попытка подключения к базе данных: ${attempt}`);
            connection = await oracledb.getConnection(dbConfig);
            console.log('Подключение к Oracle Database успешно!');
            await connection.execute(`ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ', '`);

            return;
        } catch (err) {
            console.error(`Ошибка подключения (попытка ${attempt}):`, err.message);
            if (attempt < retries) {
                console.log(`Повторное подключение через ${delay / 1000} секунд...`);
                await new Promise(resolve => setTimeout(resolve, delay));
            } else {
                console.error('Не удалось подключиться к базе данных после всех попыток.');
                throw err;
            }
        }
    }
}

// Обработчик для работы с сессией
app.get('/session', (req, res) => {
    if (!req.session.User_id) {
        req.session.User_id = null; // Инициализация User_id
    }
    res.status(200).json({ User_id: req.session.User_id, roleLevel: req.session.roleLevel});
});


app.get('/static/:fileName', (req, res) => {
    const fileName = req.params.fileName; // Получаем имя файла из URL
    const filePath = path.join(staticDir, fileName); // Формируем полный путь к файлу

    res.sendFile(filePath, (err) => {
        if (err) {
            console.error(`Ошибка при отправке файла ${fileName}:`, err.message);
            res.status(404).send('Файл не найден.');
        }
    });
});

app.get('/profile', (req, res) => {
    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        indexPath =  path.join(staticDir, 'login.html');
    }
    else
        indexPath =  path.join(staticDir, 'profile.html');

    res.sendFile(indexPath, (err) => {
        if (err) {
            console.error('Ошибка при отправке html:', err.message);
            res.status(500).send('Ошибка при загрузке страницы.');
        }
    });
})

app.get('/logout', (req, res) => {
    req.session.User_id = null;
    indexPath =  path.join(staticDir, 'login.html');

    res.sendFile(indexPath, (err) => {
        if (err) {
            console.error('Ошибка при отправке html:', err.message);
            res.status(500).send('Ошибка при загрузке страницы.');
        }
    });
})
app.get('/UpdateAccountBalance',(req, res) => {
    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        indexPath =  path.join(staticDir, 'login.html');
    }
    else
        indexPath =  path.join(staticDir, 'updateBalance.html');

    res.sendFile(indexPath, (err) => {
        if (err) {
            console.error('Ошибка при отправке html:', err.message);
            res.status(500).send('Ошибка при загрузке страницы.');
        }
    });
});
app.get('/createCash', (req, res) => {
    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        indexPath =  path.join(staticDir, 'login.html');
    }
    else
        indexPath =  path.join(staticDir, 'createCash.html');

    res.sendFile(indexPath, (err) => {
        if (err) {
            console.error('Ошибка при отправке html:', err.message);
            res.status(500).send('Ошибка при загрузке страницы.');
        }
    });
});


app.get('/transfer', (req, res) => {


    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        res.redirect('/');
    } else {
        indexPath =  path.join(staticDir, 'transfer.html');
        res.sendFile(indexPath, (err) => {
            if (err) {
                console.error('Ошибка при отправке html:', err.message);
                res.status(500).send('Ошибка при загрузке страницы.');
            }
        });
    }
});


app.get('/role', (req, res) => {


    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        res.redirect('/');
    } else {
        indexPath =  path.join(staticDir, 'role.html');
        res.sendFile(indexPath, (err) => {
            if (err) {
                console.error('Ошибка при отправке html:', err.message);
                res.status(500).send('Ошибка при загрузке страницы.');
            }
        });
    }
});

app.get('/history', (req, res) => {

    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        res.redirect('/');
    } else {
        indexPath =  path.join(staticDir, 'adminHistory.html');
        res.sendFile(indexPath, (err) => {
            if (err) {
                console.error('Ошибка при отправке html:', err.message);
                res.status(500).send('Ошибка при загрузке страницы.');
            }
        });
    }
});

app.get('/queue', (req, res) => {

    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        res.redirect('/');
    } else {
        indexPath =  path.join(staticDir, 'queue.html');
        res.sendFile(indexPath, (err) => {
            if (err) {
                console.error('Ошибка при отправке html:', err.message);
                res.status(500).send('Ошибка при загрузке страницы.');
            }
        });
    }
});

app.get('/update-user', (req, res) => {
    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        indexPath =  path.join(staticDir, 'login.html');
    }
    else
        indexPath =  path.join(staticDir, 'update-user.html');

    res.sendFile(indexPath, (err) => {
        if (err) {
            console.error('Ошибка при отправке html:', err.message);
            res.status(500).send('Ошибка при загрузке страницы.');
        }
    });
});

app.get('/', (req, res) => {
    let indexPath ; // Путь к index.html
    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        indexPath =  path.join(staticDir, 'login.html');
    }
    else
        indexPath =  path.join(staticDir, 'admin.html');

    res.sendFile(indexPath, (err) => {
        if (err) {
            console.error('Ошибка при отправке index.html:', err.message);
            res.status(500).send('Ошибка при загрузке главной страницы.');
        }
    });
});

app.get('/register', (req, res) => {
    const userId = req.session.User_id;

    if (userId === null || userId === undefined) {
        const registerPath = path.join(staticDir, 'register.html');
        res.sendFile(registerPath, (err) => {
            if (err) {
                console.error('Ошибка при отправке html:', err.message);
                res.status(500).send('Ошибка при загрузке страницы.');
            }
        });
    } else {
        res.redirect('/');
    }
});




app.post('/CreateCashAccount', async (req, res) => {
    let { cash_owner, cash_name } = req.body;
    const userId = req.session.User_id;

    // Устанавливаем cash_owner как userId, если не указан
    cash_owner = cash_owner ? Number(cash_owner) : userId;

    // Проверяем наличие необходимых параметров
    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.');
    }

    try {
        const result = await connection.execute(
            `BEGIN :result := pdbAdmin.CreateCashAccount(:executor_id, :cash_owner, :cash_name); END;`,
            {
                executor_id: { val: userId, type: oracledb.NUMBER }, // Используем userId как executor_id
                cash_owner: { val: cash_owner, type: oracledb.NUMBER },
                cash_name: { val: cash_name, type: oracledb.STRING },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING } // Получаем результат
            }
        );

        const message = result.outBinds.result;

        // Возврат результата клиенту
        res.send(message);
    } catch (err) {
        console.error('Ошибка при выполнении запроса:', err);
        res.status(500).send('Ошибка сервера: ' + err.message);
    }
});

app.post('/authorize', async (req, res) => {
    const { login, password } = req.body;

    try {
        console.log(login);
        console.log(password);
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.Authorize_User(:login, :password);
            END;`,
            {
                login: { val: login, dir: oracledb.BIND_IN },
                password: { val: password, dir: oracledb.BIND_IN },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING }
            }
        );

        const userId = result.outBinds.result;

        if (userId && !isNaN(userId)) {
            req.session.User_id = parseInt(userId, 10); // Сохраняем в сессии

            // Выполняем запрос к getRoleLevel
            const roleLevelResult = await connection.execute(
                `BEGIN
                    :roleLevel := pdbAdmin.GetUserRoleLevel(:userId);
                END;`,
                {
                    userId: { val: req.session.User_id, dir: oracledb.BIND_IN },
                    roleLevel: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
                }
            );

            const roleLevel = roleLevelResult.outBinds.roleLevel;

            if (roleLevel !== null) {
                req.session.Role_level = roleLevel; // Сохраняем уровень роли в сессию
                res.send(`
                    <html>
                        <body>
                            <h1>Вход успешен!</h1>
                            <button onclick="window.location.href='/'">ОК</button>
                        </body>
                    </html>
                `);
            } else {
                res.send(`
                    <html>
                        <body>
                            <h1>Ошибка получения уровня роли</h1>
                            <button onclick="window.history.back()">Повторить</button>
                        </body>
                    </html>
                `);
            }
        } else {
            // Если авторизация не удалась, выводим сообщение об ошибке
            res.send(`
                <html>
                    <body>
                        <h1>Ошибка авторизации</h1>
                        <p>Неверный логин или пароль.</p>
                        <button onclick="window.history.back()">Повторить</button>
                    </body>
                </html>
            `);
        }
    } catch (err) {
        console.error('Ошибка авторизации:', err.message);
        res.status(500).json({ error: 'Ошибка сервера.' });
    }
});


// Эндпоинт для регистрации
app.post('/register', async (req, res) => {
    const { login, password, name, lastName, number, pasport } = req.body;
    const role = 3;

    try {

        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.Register_User(:login, :password, :name, :lastName, :number, :pasport, :role);
            END;`,
            {
                login: { val: login, dir: oracledb.BIND_IN,type: oracledb.STRING },
                password: { val: password, dir: oracledb.BIND_IN, type: oracledb.STRING },
                name: { val: name, dir: oracledb.BIND_IN, type: oracledb.STRING },
                lastName: { val: lastName, dir: oracledb.BIND_IN, type: oracledb.STRING },
                number: { val: number, dir: oracledb.BIND_IN, type: oracledb.STRING },
                pasport: { val: pasport, dir: oracledb.BIND_IN, type: oracledb.STRING },
                role: { val: role, dir: oracledb.BIND_IN, type: oracledb.NUMER },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
            }
        );

        const message = result.outBinds.result;
        res.status(200).json({ message });
    } catch (err) {
        console.error('Ошибка регистрации:', err.message);
        res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

app.post('/transfer', async (req, res) => {
    const userId = req.session.User_id;
    let { senderCashId, receiverCashId, transferAmount } = req.body;
    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.');
    }
    console.log(senderCashId, receiverCashId, transferAmount )
    try {

        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.ProcessTransfer(:userId, :senderCashId, :receiverCashId, :amount);
            END;`,
            {
                userId: { val: userId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                senderCashId: { val: Number(senderCashId), dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                receiverCashId: { val: Number(receiverCashId), dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                amount: { val: Number(transferAmount), dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 } // Для получения результата
            }
        );

        res.json({ message: result.outBinds.result });
    } catch (err) {
        console.error('Ошибка при получении информации о пользователе:', err.message);
        return res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

app.post('/userinfo', async (req, res) => {
    const requesterId = req.session.User_id;
    let targetUserId = req.body.targetUserId;

    console.log('requesterId:', requesterId);
    console.log('targetUserId:', targetUserId);

    // Преобразуем id в число
    const numericRequesterId = Number(requesterId);
    let numericTargetUserId = targetUserId ? Number(targetUserId) : numericRequesterId;

    // Проверяем, что преобразованные ID действительные числа
    if (isNaN(numericRequesterId)) {
        return res.status(400).json({ error: 'Пользователь не авторизован.' });
    }

    try {
        // Выполняем вызов процедуры
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.Get_User_Info(:requesterId, :targetUserId, :errorMessage);
            END;`,
            {
                requesterId: { val: numericRequesterId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                targetUserId: { val: numericTargetUserId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                errorMessage: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 },
                result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
            }
        );

        const errorMessage = result.outBinds.errorMessage;

        // Проверяем наличие ошибки, возвращенной процедурой
        if (errorMessage) {
            console.error('Ошибка из процедуры:', errorMessage);
            return res.status(400).json({ error: errorMessage });
        }

        const cursor = result.outBinds.result;
        const resultSet = await cursor.getRow(); // Получаем одну строку

        await cursor.close();

        if (resultSet) {
            res.json({
                userInfo: {
                    login: resultSet[1],        // login
                    userName: resultSet[2],     // user_name
                    lastName: resultSet[3],     // last_name
                    phoneNumber: resultSet[4],  // phone_number
                    pasport: resultSet[5],      // pasport
                },
            });
        } else {
            res.json({ userInfo: null }); // Если пользователь не найден
        }
    } catch (err) {
        console.error('Ошибка при получении информации о пользователе:', err.message);
        return res.status(500).json({ error: 'Ошибка сервера.' });
    }
});



app.post('/update-user', async (req, res) => {
    const executorId = req.session.User_id;  // ID пользователя, выполняющего операцию
    let {
        targetId,
        newLogin,
        newPass,
        newUserName,
        newLastName,
        newPhoneNumber,
        newPasport,
    } = req.body;
    targetId = targetId || executorId;
    // Проверка на авторизацию
    if (!executorId) {
        return res.status(401).json({ error: 'Пользователь не авторизован.' });
    }

    try {
        // Выполнение PL/SQL блока с вызовом функции
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.UpdateUser(
                    :executorId,
                    :targetId,
                    :newLogin,
                    :newPass,
                    :newUserName,
                    :newLastName,
                    :newPhoneNumber,
                    :newPasport
                );
            END;`,
            {
                executorId: { val: executorId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                targetId: { val: targetId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                newLogin: { val: newLogin, dir: oracledb.BIND_IN, type: oracledb.STRING },
                newPass: { val: newPass, dir: oracledb.BIND_IN, type: oracledb.STRING },
                newUserName: { val: newUserName, dir: oracledb.BIND_IN, type: oracledb.STRING },
                newLastName: { val: newLastName, dir: oracledb.BIND_IN, type: oracledb.STRING },
                newPhoneNumber: { val: newPhoneNumber, dir: oracledb.BIND_IN, type: oracledb.STRING },
                newPasport: { val: newPasport, dir: oracledb.BIND_IN, type: oracledb.STRING },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
            }
        );

        // Получаем результат выполнения функции
        const message = result.outBinds.result;

        // Отправка результата клиенту
        res.json({ message });
    } catch (error) {
        console.error('Ошибка при обновлении пользователя:', error);
        res.status(500).json({ error: 'Ошибка при обновлении пользователя.' });
    }
});

app.post('/UpdateAccountBalance', async (req, res) => {
    const { cashId, amount } = req.body; // Извлечение данных из тела запроса
    const userId = req.session.User_id;

    // Устанавливаем cash_owner как userId, если не указан

    // Проверяем наличие необходимых параметров
    if (!userId) {
        return         res.json({ message: 'Пользователь не авторизован.' });
    }

    // Проверка на наличие всех необходимых параметров
    if (cashId === undefined || amount === undefined) {
        return res.status(400).json({ error: 'Параметры userId, cashId и amount обязательны.' });
    }

    try {
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.UpdateAccountBalance(:userId, :cashId, :amount);
            END;`,
            {
                userId: { val: userId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                cashId: { val: Number(cashId), dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                amount: { val: Number(amount), dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 }, // Для получения результата
            }
        );

        const resultMessage = result.outBinds.result;

        // Возвращаем результат выполнения функции
        res.json({ message: resultMessage });
    } catch (error) {
        console.error('Ошибка при обновлении баланса счета:', error);
        res.status(500).json({ error: 'Ошибка при обновлении баланса счета:' + error  });
    }
});
app.post('/cash-accounts', async (req, res) => {
    const requesterId = req.session.User_id; // ID пользователя, отправившего запрос
    const { ownerId } = req.body;
    const numericOwnerId = ownerId ? Number(ownerId) : null;
    if (!requesterId) {
        return res.status(400).json({ error: 'Пользователь не авторизован.' });
    }
    console.log(`Requester ID: ${requesterId}, Owner ID: ${numericOwnerId}`);

    try {
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.Get_Cash_Accounts_admin(:requesterId, :ownerId, :errorMessage);
            END;`,
            {
                requesterId: { val: requesterId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                ownerId: { val: numericOwnerId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                errorMessage: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 },
                result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
            }
        );

        const errorMessage = result.outBinds.errorMessage;

        // Если есть ошибка, возвращаем её клиенту
        if (errorMessage) {
            return res.status(403).json({ error: errorMessage });
        }

        const cursor = result.outBinds.result;

        // Если курсор отсутствует, возвращаем сообщение о недоступности данных
        if (!cursor) {
            return res.status(404).json({ error: 'Данные не найдены или доступ запрещен.' });
        }

        // Считываем данные из курсора
        const cashAccounts = [];
        let row;
        while ((row = await cursor.getRow()) !== undefined) {
            if (row && row.length >= 7) { // Проверяем структуру строки
                cashAccounts.push({
                    cashId: row[0],       // Cash_id
                    owner: row[1],        // Cash_owner
                    balance: row[2],      // Balance
                    cashName: row[3],     // Cash_name
                    isBlocked: row[4],    // IsBlocked
                    creationDate: row[5], // Creation_date
                    currencyId: row[6],   // Currency_id
                });
            }
        }

        // Если данные не найдены
        if (cashAccounts.length === 0) {
            return res.status(404).json({ error: 'Данные не найдены.' });
        }

        await cursor.close();

        // Успешный ответ с массивом счетов
        res.json({ cashAccounts });
    } catch (error) {
        console.error('Ошибка при получении информации о счетах:', error.message);
        res.status(500).json({ error: 'Ошибка при получении информации о счетах.' });
    }
});

app.post('/getHistory', async (req, res) => {
    const requesterId = req.session.User_id; // Получаем ID текущего пользователя
    const { filter_id = null } = req.body; // Устанавливаем filter_id в null, если он не передан

    const targetUserId = filter_id ? filter_id : null;

    try {
        const result = await connection.execute(
            `BEGIN
                :cursor := pdbAdmin.GetUncryptHistory(:requesterId, :targetUserId, :result);
            END;`,
            {
                requesterId: { val: requesterId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                targetUserId: { val: targetUserId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 },
                cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
            }
        );

        // Если есть поле `result`, возвращаем только его
        if (result.outBinds.result) {
            return res.json({ result: result.outBinds.result });
        }

        // Получаем данные из курсора
        const cursor = result.outBinds.cursor;
        const rows = await cursor.getRows();
        cursor.close(); // Закрываем курсор после получения данных
        console.log(rows);
        res.json({ history: rows });

    } catch (error) {
        console.error('Ошибка при обработке истории:', error.message);
        res.status(500).json({ error: 'Ошибка сервера.' });
    }
});


app.post('/getQueue', async (req, res) => {
    const requesterId = req.session.User_id; // Получаем ID текущего пользователя
    const { filter_id } = req.body;

    // Если filter_id указан, то он становится targetUserId
    const targetUserId = filter_id ? filter_id : null;
    if (!requesterId) {
        return res.status(400).send('Пользователь не авторизован.');
    }
    try {
        const result = await connection.execute(
            `BEGIN
                :cursor := pdbAdmin.GetUncryptQueue(:requesterId, :targetUserId, :result);
            END;`,
            {
                requesterId: { val: requesterId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                targetUserId: { val: targetUserId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 },
                cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
            }
        );

        // Если есть поле `result`, возвращаем только его
        if (result.outBinds.result) {
            return res.json({ result: result.outBinds.result });
        }

        // Получаем данные из курсора
        const cursor = result.outBinds.cursor;
        const rows = await cursor.getRows();
        cursor.close(); // Закрываем курсор после получения данных
        console.log(rows);
        res.json({ history: rows });

    } catch (error) {
        console.error('Ошибка при обработке истории:', error.message);
        res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

app.post('/executeQueue', async (req, res) => {
    const operatorId = req.session.User_id; // Получаем ID оператора из сессии
    const { operation_id } = req.body; // Получаем ID операции из запроса

    // Проверка авторизации
    if (!operatorId) {
        return res.status(400).send('Пользователь не авторизован.');
    }

    if (!operation_id) {
        return res.status(400).send('ID операции не указан.');
    }

    try {
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.ExecuteQueueOperation(:operatorId, :operationId);
            END;`,
            {
                operatorId: { val: operatorId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                operationId: { val: Number(operation_id), dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 } // Для получения результата
            }
        );

        // Отправляем результат обратно в клиент
        res.json({ message: result.outBinds.result });
    } catch (err) {
        console.error('Ошибка при выполнении операции:', err.message);
        return res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

app.post('/deleteQueueRow', async (req, res) => {
    const userId = req.session.User_id; // Получаем ID пользователя из сессии
    const { operation_id } = req.body;   // Получаем ID операции из тела запроса

    // Проверяем наличие необходимых параметров
    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.');
    }

    if (!operation_id) {
        return res.status(400).send('Не указан ID операции для удаления.');
    }

    try {
        const result = await connection.execute(
            `BEGIN :result := pdbAdmin.DeleteQueueRow(:user_id, :operation_id); END;`,
            {
                user_id: { val: userId, type: oracledb.NUMBER }, // ID пользователя из сессии
                operation_id: { val: operation_id, type: oracledb.NUMBER }, // ID операции из запроса
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING } // Получаем результат
            }
        );

        const message = result.outBinds.result;

        // Возврат результата клиенту
        res.send(message);
    } catch (err) {
        console.error('Ошибка при выполнении запроса:', err);
        res.status(500).send('Ошибка сервера: ' + err.message);
    }
});


app.post('/updateQueue', async (req, res) => {
    const userId = req.session.User_id; // Получаем user_id из сессии
    const { operation_id, new_cash_to, new_amount } = req.body; // Получаем данные из тела запроса

    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.');
    }

    try {
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.UpdateQueueRow(:userId, :operation_id, :new_cash_to, :new_amount);
            END;`,
            {
                userId: { val: userId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                operation_id: { val: Number(operation_id), dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                new_cash_to: { val: new_cash_to !== undefined && new_cash_to !== null ? String(new_cash_to) : null, dir: oracledb.BIND_IN, type: oracledb.STRING },
                new_amount: { val: new_amount !== undefined && new_amount !== null ? String(new_amount) : null, dir: oracledb.BIND_IN, type: oracledb.STRING },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 } // Для получения результата
            }
        );


        res.json({ message: result.outBinds.result }); // Возвращаем результат
    } catch (err) {
        console.error('Ошибка при обновлении операции в очереди:', err.message);
        return res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

app.post('/getRole', async (req, res) => {

    try {
        const userId = req.session.User_id;
        if (!userId) {
            return res.status(401).json({ error: 'Пользователь не авторизован' });
        }

        const binds = {
            p_user_id: { val: userId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
            p_error_msg: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 },
            result_cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
        };

        const result = await connection.execute(
            `BEGIN :result_cursor := pdbAdmin.GetRole(:p_user_id, :p_error_msg); END;`,
            binds
        );

        // Обработка результата
        const errorMsg = result.outBinds.p_error_msg;
        const resultCursor = result.outBinds.result_cursor;

        if (errorMsg) {
            return res.status(403).json({ error: errorMsg });
        }

        // Читаем данные из курсора
        const rows = [];
        let row;
        while ((row = await resultCursor.getRow())) {
            rows.push(row);
        }
        await resultCursor.close();

        // Возвращаем данные
        res.status(200).json({ roles: rows });
    } catch (err) {
        console.error('Ошибка при обработке запроса:', err);
        res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
});


app.post('/deleteUser', async (req, res) => {
    const userId = req.session.User_id; // ID исполнителя
    let { target_user_id } = req.body; // ID пользователя, который будет удален

    // Если target_user_id не указан, присваиваем ему значение userId
    target_user_id = target_user_id ? Number(target_user_id) : userId;

    // Проверяем, авторизован ли пользователь
    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.');
    }

    try {
        // Выполняем PL/SQL блок для вызова функции DeleteUser
        const result = await connection.execute(
            `BEGIN :result := pdbAdmin.DeleteUser(:executor_id, :target_user_id); END;`,
            {
                executor_id: { val: userId, type: oracledb.NUMBER }, // ID исполнителя
                target_user_id: { val: target_user_id, type: oracledb.NUMBER }, // ID пользователя для удаления
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING } // Получаем результат
            }
        );

        const message = result.outBinds.result; // Получаем сообщение от функции

        // Возвращаем результат клиенту
        if(message === 'Успех: Пользователь удален.')
            req.session.User_id = null;
        res.json({ message });
    } catch (err) {
        console.error('Ошибка при выполнении запроса:', err);
        res.status(500).send('Ошибка сервера: ' + err.message);
    }
});


app.post('/deleteCashAccount', async (req, res) => {
    const userId = req.session.User_id; // Получаем ID пользователя из сессии
    const { cash_id } = req.body; // Получаем ID счета из тела запроса

    // Проверяем наличие необходимых параметров
    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.');
    }

    if (!cash_id) {
        return res.status(400).send('Не указан ID счета для удаления.');
    }
    console.log(cash_id);
    try {
        const result = await connection.execute(
            `BEGIN :result := pdbAdmin.DeleteCashAccount(:user_id, :cash_id); END;`,
            {
                user_id: { val: userId, type: oracledb.NUMBER }, // ID пользователя из сессии
                cash_id: { val: `${cash_id}`, type: oracledb.STRING }, // ID счета из запроса
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING } // Получаем результат
            }
        );

        const message = result.outBinds.result;

        // Возврат результата клиенту
        res.json({ message });
    } catch (err) {
        console.error('Ошибка при выполнении запроса:', err);
        res.status(500).send('Ошибка сервера: ' + err.message);
    }
});




app.post('/getCurrencies', async (req, res) => {
    try {
        const result = await connection.execute(
            `BEGIN
                :cursor := pdbAdmin.Get_Currencies();
            END;`,
            {
                cursor: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
            }
        );

        // Получаем данные из курсора
        const cursor = result.outBinds.cursor;
        const rows = await cursor.getRows(); // Получаем все строки из курсора
        cursor.close(); // Закрываем курсор после получения данных

        res.json({ currencies: rows });
    } catch (error) {
        console.error('Ошибка при получении валют:', error.message);
        res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

// Эндпоинт для разблокировки счета
app.post('/unblockAccount', async (req, res) => {
    const { cashId } = req.body; // Извлечение данных из тела запроса
    const userId = req.session.User_id;

    // Проверяем наличие необходимых параметров
    if (!userId) {
        return res.status(401).json({ message: 'Пользователь не авторизован.' });
    }

    if (cashId === undefined) {
        return res.status(400).json({ error: 'Параметр cashId обязателен.' });
    }

    try {
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.Unblock_Cash_Account(:userId, :cashId);
            END;`,
            {
                userId: { val: userId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                cashId: { val: cashId, dir: oracledb.BIND_IN, type: oracledb.STRING },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 },
            }
        );

        const resultMessage = result.outBinds.result;

        // Возвращаем результат выполнения функции
        res.json({ message: resultMessage });
    } catch (error) {
        console.error('Ошибка при разблокировке счета:', error);
        res.status(500).json({ error: 'Ошибка при разблокировке счета: ' + error });
    }
});


app.post('/update-cash-account', async (req, res) => {
    const userId = req.session.User_id; // Получение идентификатора пользователя из сессии
    const { cashId, newCashName, newCurrencyId } = req.body; // Получение данных из тела запроса

    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.'); // Проверка авторизации пользователя
    }
    console.log(cashId);
    try {
        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.UpdateInfoCashAccount(:userId, :cashId, :newCashName, :newCurrencyId);
            END;`,
            {
                userId: { val: userId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                cashId: { val: cashId, dir: oracledb.BIND_IN, type: oracledb.STRING },
                newCashName: { val: newCashName, dir: oracledb.BIND_IN, type: oracledb.STRING },
                newCurrencyId: { val: newCurrencyId, dir: oracledb.BIND_IN, type: oracledb.STRING },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 } // Для получения результата
            }
        );

        // Отправка успешного ответа с результатом
        res.json({ message: result.outBinds.result });
    } catch (err) {
        console.error('Ошибка при обновлении информации о счете:', err.message);
        return res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

app.post('/block-cash-account', async (req, res) => {
    const userId = req.session.User_id; // Получение идентификатора пользователя из сессии
    const { cashId } = req.body; // Получение данных из тела запроса

    if (!userId) {
        return res.status(400).send('Пользователь не авторизован.'); // Проверка авторизации пользователя
    }

    try {
        console.log(`Блокировка счета: cashId = ${cashId}, userId = ${userId}`);

        const result = await connection.execute(
            `BEGIN
                :result := pdbAdmin.Block_Cash_Account(:userId, :cashId);
            END;`,
            {
                userId: { val: userId, dir: oracledb.BIND_IN, type: oracledb.NUMBER },
                cashId: { val: cashId, dir: oracledb.BIND_IN, type: oracledb.STRING },
                result: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 4000 } // Для получения результата
            }
        );

        // Отправка успешного ответа с результатом
        res.json({ message: result.outBinds.result });
    } catch (err) {
        console.error('Ошибка при блокировке кассового счета:', err.message);
        return res.status(500).json({ error: 'Ошибка сервера.' });
    }
});

// Запуск сервера
app.listen(4000, async () => {
    console.log('Сервер запущен на http://localhost:4000/');
    try {
        await connectToDatabase();
    } catch (err) {
        console.error('Сервер работает, но база данных недоступна. Попробуйте снова позже.');
    }
});
