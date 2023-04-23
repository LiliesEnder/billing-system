# Отчет об ошибках

## Endpoint abonent/pay
1. По ТЗ требуется путь = abonent/pay, по факту путь является /pay
2. Формат входных данных не соответсвует ТЗ. Требуется 2 поля:
   1. phone = строке с номером телефеона
   2. money = количество денег на зачисление
3. Возвращает ошибку 400 при валидных данных:
```json
{
    "phone": "+79001002030",
    "money": 10.5
}
```
## Endpoint manager/change-tariff
1. По ТЗ требуется путь = manager/change-tariff, по факту путь является /change-tariff
2. Возвращает ошибку 500 при валидных данных:
```json
{
   "userPhone": "79001002030",
   "newTarrifId": "11"
}
```
Ответ:
```json
{
   "status": 500,
   "error": "Internal Server Error",
   ...
   "message": "The given id must not be null",
   ...
}
```