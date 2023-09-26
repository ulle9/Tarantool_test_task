# Tarantool_test_task
Task:
1) скачать/собрать тарантул
2) запустить тестовое приложение
3) реализовать kv-хранилище доступное по http
4) выложить на гитхаб

API:
- POST /kv body: {key: "test", "value": {SOME ARBITRARY JSON}}
- PUT kv/{id} body: {"value": {SOME ARBITRARY JSON}}
- GET kv/{id}
- DELETE kv/{id}

- POST  возвращает 409 если ключ уже существует,
- POST, PUT возвращают 400 если боди некорректное
- PUT, GET, DELETE возвращает 404 если такого ключа нет
- все операции логируются
