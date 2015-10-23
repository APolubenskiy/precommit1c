﻿#Использовать cmdline
#Использовать logos
#Использовать tempfiles
#Использовать asserts
#Использовать v8runner
#Использовать strings

Перем Лог;
Перем КодВозврата;
Перем мВозможныеКоманды;

Функция ВозможныеКоманды()
	
	Если мВозможныеКоманды = Неопределено Тогда
		мВозможныеКоманды = Новый Структура;
		мВозможныеКоманды.Вставить("Декомпилировать", "--decompile");
		мВозможныеКоманды.Вставить("Помощь", "--help");
		мВозможныеКоманды.Вставить("ОбработатьИзмененияИзГит", "--git-precommit");
	КонецЕсли;
	
	Возврат мВозможныеКоманды;
	
КонецФункции

Функция ЗапускВКоманднойСтроке()
	
	КодВозврата = 0;
	
	Если ТекущийСценарий().Источник <> СтартовыйСценарий().Источник Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Попытка
	
		Парсер = Новый ПарсерАргументовКоманднойСтроки();
		
		ДобавитьОписаниеКомандыДекомпилировать(Парсер);
		ДобавитьОписаниеКомандыПомощь(Парсер);
		ДобавитьОписаниеКомандыИзмененияПоЖурналуГит(Парсер);
		
		Аргументы = Парсер.РазобратьКоманду(АргументыКоманднойСтроки);
		
		Команда = Аргументы.Команда;
		Лог.Отладка("Передана команда: "+Команда);
		Для Каждого Параметр Из Аргументы.ЗначенияПараметров Цикл
			Лог.Отладка(Параметр.Ключ + " = " + Параметр.Значение);
		КонецЦикла;
		
		Если Команда = ВозможныеКоманды().Декомпилировать Тогда
			Декомпилировать(Аргументы.ЗначенияПараметров["ПутьВходящихДанных"], Аргументы.ЗначенияПараметров["ВыходнойКаталог"]);
		ИначеЕсли Команда = ВозможныеКоманды().Помощь Тогда
			ВывестиСправку();
		ИначеЕсли Команда = ВозможныеКоманды().ОбработатьИзмененияИзГит Тогда
			ОбработатьИзмененияИзГит(Аргументы.ЗначенияПараметров["ВыходнойКаталог"]);
		КонецЕсли;
		
	Исключение
		Лог.Ошибка(ОписаниеОшибки());
		КодВозврата = 1;
	КонецПопытки;
	
	Возврат Истина;
	
КонецФункции

Процедура ДобавитьОписаниеКомандыДекомпилировать(Знач Парсер)
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ВозможныеКоманды().Декомпилировать);
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьВходящихДанных");
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ВыходнойКаталог");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
КонецПроцедуры

Процедура ДобавитьОписаниеКомандыПомощь(Знач Парсер)
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ВозможныеКоманды().Помощь);
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
КонецПроцедуры

Процедура ДобавитьОписаниеКомандыИзмененияПоЖурналуГит(Знач Парсер)
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ВозможныеКоманды().ОбработатьИзмененияИзГит);
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ВыходнойКаталог");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры

Процедура Инициализация()
	Лог = Логирование.ПолучитьЛог("oscript.app.v8files-extractor");
	//Лог.УстановитьУровень(УровниЛога.Отладка);
КонецПроцедуры


/////////////////////////////////////////////////////////////////////////////
// РЕАЛИЗАЦИЯ КОМАНД

Процедура Декомпилировать(Знач Путь, Знач КаталогВыгрузки) Экспорт
	Файл = Новый Файл(Путь);
	Если Файл.ЭтоКаталог() Тогда
		РазобратьКаталог(Файл.ПолноеИмя, КаталогВыгрузки);
	Иначе
		РазобратьФайл(Файл.ПолноеИмя, КаталогВыгрузки);
	КонецЕсли;
КонецПроцедуры

Процедура РазобратьКаталог(Знач ПутьКаталога, Знач КаталогВыгрузки) Экспорт
	Лог.Информация("Подготовка выгрузки каталога "+ПутьКаталога+" в каталог " + КаталогВыгрузки);
	РазобратьКаталогВнутр(ПутьКаталога, КаталогВыгрузки);
	Лог.Информация("Завершена выгрузки каталога "+ПутьКаталога+" в каталог " + КаталогВыгрузки);
КонецПроцедуры

Функция РазобратьФайл(Знач ПутьФайла, Знач КаталогВыгрузки) Экспорт
	Лог.Информация("Подготовка выгрузки файла "+ПутьФайла+" в каталог " + КаталогВыгрузки);
	
	КаталогИсходников = РазобратьФайлВнутр(ПутьФайла, КаталогВыгрузки);
	
	Лог.Информация("Завершена выгрузка файла "+ПутьФайла+" в каталог " + КаталогВыгрузки);
	
	Возврат КаталогИсходников;
	
КонецФункции

Процедура РазобратьКаталогВнутр(Знач ПутьКаталога, Знач КаталогВыгрузки)
	ОбъектКаталога = Новый Файл(ПутьКаталога);
	ИмяКаталогаВыгрузки = Новый Файл(КаталогВыгрузки).Имя;
	Лог.Информация("Вошел в каталог "+ОбъектКаталога.Имя);
	
	Файлы = НайтиФайлы(ПутьКаталога, ПолучитьМаскуВсеФайлы());
	Для Каждого Файл из Файлы Цикл
		Если Файл.ЭтоКаталог() Тогда
			РазобратьКаталогВнутр(Файл.ПолноеИмя, ОбъединитьПути(КаталогВыгрузки, Файл.Имя));
		ИначеЕсли ТипФайлаПоддерживается(Файл) Тогда
			Лог.Информация("Подготовка выгрузки файла "+Файл.Имя+" в каталог " + ИмяКаталогаВыгрузки);
			РазобратьФайлВнутр(Файл.ПолноеИмя, КаталогВыгрузки);
			Лог.Информация("Завершена выгрузка файла "+Файл.Имя+" в каталог " + ИмяКаталогаВыгрузки);
		КонецЕсли;
	КонецЦикла;
	
	Лог.Информация("Вышел из каталога "+ОбъектКаталога.Имя);
КонецПроцедуры

Функция ТипФайлаПоддерживается(Файл)
	Если ПустаяСтрока(Файл.Расширение) Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Поз = Найти(".epf,.erf,", Файл.Расширение+",");
	Возврат Поз > 0;
	
КонецФункции

Функция РазобратьФайлВнутр(Знач ПутьФайла, Знач КаталогВыгрузки)
	
	Файл = Новый Файл(ПутьФайла);
	Если Не ТипФайлаПоддерживается(Файл) Тогда
		ВызватьИсключение "Тип файла """+Файл.Расширение+""" не поддерживается";
	КонецЕсли;
	
	Ожидаем.Что(Файл.Существует(), "Файл " + ПутьФайла + " должен существовать").ЭтоИстина();
	
	ПапкаИсходников = Новый Файл(ОбъединитьПути(КаталогВыгрузки, Файл.ИмяБезРасширения));
	ОбеспечитьПустойКаталог(ПапкаИсходников);
	ЗапуститьРаспаковку(Файл, ПапкаИсходников);
	
	Возврат ПапкаИсходников.ПолноеИмя;
	
КонецФункции

Процедура ЗапуститьРаспаковку(Знач Файл, Знач ПапкаИсходников)
	
	Лог.Отладка("Запускаем распаковку файла");
	
	Конфигуратор = Новый УправлениеКонфигуратором();
	КаталогВременнойИБ = ВременныеФайлы.СоздатьКаталог();
	Конфигуратор.КаталогСборки(КаталогВременнойИБ);
	
	ЛогКонфигуратора = Логирование.ПолучитьЛог("oscript.lib.v8runner");
	ЛогКонфигуратора.УстановитьУровень(Лог.Уровень());
	
	Параметры = Конфигуратор.ПолучитьПараметрыЗапуска();
	Параметры[0] = "ENTERPRISE";
	
	ПутьV8Reader = ОбъединитьПути(ТекущийСценарий().Каталог, "v8Reader", "V8Reader.epf");
	Лог.Отладка("Путь к V8Reader: " + ПутьV8Reader);
	Ожидаем.Что(Новый Файл(ПутьV8Reader).Существует()).ЭтоИстина();
	
	КоманднаяСтрокаV8Reader = СтрЗаменить("/C""decompile;pathtocf;%1;pathout;%2;convert-mxl2txt;ЗавершитьРаботуПосле;""","%1", Файл.ПолноеИмя);
	КоманднаяСтрокаV8Reader = СтрЗаменить(КоманднаяСтрокаV8Reader,"%2", ПапкаИсходников.ПолноеИмя);
	
	Лог.Отладка("Командная строка V8Reader: " + КоманднаяСтрокаV8Reader);

	Параметры.Добавить("/RunModeOrdinaryApplication");
	Параметры.Добавить("/Execute """ + ПутьV8Reader + """");
	Параметры.Добавить(КоманднаяСтрокаV8Reader);
	
	Конфигуратор.ВыполнитьКоманду(Параметры);
	Лог.Отладка("Вывод 1С:Предприятия - " + Конфигуратор.ВыводКоманды());
	Лог.Отладка("Очищаем каталог временной ИБ");
	ВременныеФайлы.УдалитьФайл(КаталогВременнойИБ);
	
КонецПроцедуры

Процедура ОбеспечитьПустойКаталог(Знач ФайлОбъектКаталога)
	
	Если Не ФайлОбъектКаталога.Существует() Тогда
		Лог.Отладка("Создаем новый каталог " + ФайлОбъектКаталога.ПолноеИмя);
		СоздатьКаталог(ФайлОбъектКаталога.ПолноеИмя);
	ИначеЕсли ФайлОбъектКаталога.ЭтоКаталог() Тогда
		Лог.Отладка("Очищаем каталог " + ФайлОбъектКаталога.ПолноеИмя);
		УдалитьФайлы(ФайлОбъектКаталога.ПолноеИмя, ПолучитьМаскуВсеФайлы());
	Иначе
		ВызватьИсключение "Путь " + ФайлОбъектКаталога.ПолноеИмя + " не является каталогом. Выгрузка невозможна";
	КонецЕсли;
	
КонецПроцедуры


Процедура ВывестиСправку()
	Сообщить("Утилита сборки/разборки внешних файлов 1С");
	Сообщить(" ");
	Сообщить("Параметры командной строки:");
	Сообщить("	--decompile inputPath outputPath");
	Сообщить("		Разбор файлов на исходники");
	
	Сообщить("	--help");
	Сообщить("		Показ этого экрана");
	Сообщить("	--git-precommit outputPath");
	Сообщить("		Запустить чтение индекса из git и определить список файлов для разбора, разложить их и добавить исходники в индекс");
КонецПроцедуры


Процедура ОбработатьИзмененияИзГит(Знач ВыходнойКаталог)
	
	Если ПустаяСтрока(ВыходнойКаталог) Тогда
		ВыходнойКаталог = "src";
	КонецЕсли;
	
	ЖурналИзмененийГитСтрокой = ПолучитьЖурналИзмененийГит();
	ИменаФайлов = ПолучитьИменаИзЖурналаИзмененийГит(ЖурналИзмененийГитСтрокой);
	
	КореньРепо = ТекущийКаталог();
	КаталогИсходников = ОбъединитьПути(КореньРепо, ВыходнойКаталог);
	СписокНовыхКаталогов = Новый Массив;
	Для Каждого Файл Из ИменаФайлов Цикл
		Лог.Отладка("Изучаю файл из журнала git " + Файл);
		Если ТипФайлаПоддерживается(Новый Файл(Файл)) Тогда
			Лог.Отладка("Получен из журнала git файл " + Файл);
			ПолныйПуть = ОбъединитьПути(КореньРепо, Файл);
			СписокНовыхКаталогов.Добавить(РазобратьФайл(ПолныйПуть, КаталогИсходников));
		КонецЕсли;
	КонецЦикла;
	
	ДобавитьИсходникиВГит(СписокНовыхКаталогов);
	
КонецПроцедуры

Функция ПолучитьЖурналИзмененийГит()
	
	Перем КодВозврата;
	
	Лог.Отладка("Запускаю git diff-index");
	Вывод = ПолучитьВыводПроцесса("git diff-index --name-status --cached HEAD -z", КодВозврата);
	Лог.Отладка("Вывод git diff-index: " + Вывод);
	Если КодВозврата <> 0 Тогда
		Лог.Отладка("Запускаю git status");
		Вывод = ПолучитьВыводПроцесса("git status --porcelain -z", КодВозврата);
		Лог.Отладка("Вывод git status: " + Вывод);
		
		Если КодВозврата <> 0 Тогда
			ВызватьИсключение "Не удалось собрать журнал изменений git";
		КонецЕсли;
		
	КонецЕсли;
	
	Возврат Вывод;
	
КонецФункции

Функция ПолучитьВыводПроцесса(Знач КоманднаяСтрока, КодВозврата)
	
	// Это для dev версии 1.0.11
	//Процесс = СоздатьПроцесс(КоманднаяСтрока, , Истина,, КодировкаТекста.UTF8);
	// Процесс.Запустить();
	// Вывод = "";
	
	// Процесс.ОжидатьЗавершения();
	
	// Вывод = Вывод + Процесс.ПотокВывода.Прочитать();
	// Вывод = Вывод + Процесс.ПотокОшибок.Прочитать();
	
	// КодВозврата = Процесс.КодВозврата;
	
	ЛогФайл = ВременныеФайлы.НовоеИмяФайла();
	СтрокаЗапуска = "cmd /C """ + КоманднаяСтрока + " > """ + ЛогФайл + """ 2>&1""";
	Лог.Отладка(СтрокаЗапуска);
	ЗапуститьПриложение(СтрокаЗапуска,, Истина, КодВозврата);
	Лог.Отладка("Код возврата: " + КодВозврата);
	ЧтениеТекста = Новый ЧтениеТекста(ЛогФайл, "utf-8");
	Вывод = ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	ВременныеФайлы.УдалитьФайл(ЛогФайл);
	
	Возврат Вывод;
	
КонецФункции

Функция ПолучитьИменаИзЖурналаИзмененийГит(Знач ЖурналИзмененийГит) Экспорт
	МассивИмен = Новый Массив;
	Если Найти(ЖурналИзмененийГит, Символы.ПС) > 0 Тогда
		МассивСтрокЖурнала = СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(ЖурналИзмененийГит, Символы.ПС);
	Иначе
		ЖурналИзмененийГит = СтрЗаменить(ЖурналИзмененийГит, "A"+Символ(0), "A"+" ");
		ЖурналИзмененийГит = СтрЗаменить(ЖурналИзмененийГит, "M"+Символ(0), "M"+" ");
		ЖурналИзмененийГит = СтрЗаменить(ЖурналИзмененийГит, Символ(0), Символы.ПС);
		МассивСтрокЖурнала = СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(ЖурналИзмененийГит, Символы.ПС); //Символ(0));
	КонецЕсли;
	
	Лог.Отладка("ЖурналИзмененийГит:");
	Для Каждого СтрокаЖурнала Из МассивСтрокЖурнала Цикл
		Лог.Отладка("	<"+СтрокаЖурнала +">");
		СтрокаЖурнала = СокрЛ(СтрокаЖурнала);
		СимволИзменений = Лев(СтрокаЖурнала, 1);
		Если СимволИзменений = "A" или СимволИзменений = "M" Тогда
			ИмяФайла = СокрЛП(Сред(СтрокаЖурнала, 2));
			ИмяФайла = СтрЗаменить(ИмяФайла, Символ(0), "");
			МассивИмен.Добавить(ИмяФайла);
			Лог.Отладка("		В журнале git найдено имя файла <"+ИмяФайла+">");
		КонецЕсли;
	КонецЦикла;
	Возврат МассивИмен;
КонецФункции

Процедура ДобавитьИсходникиВГит(Знач СписокНовыхКаталогов)

	Перем КодВозврата;
	
	Для Каждого Каталог Из СписокНовыхКаталогов Цикл
		
		Лог.Отладка("Запуск git add для каталога " + Каталог);
		Вывод = ПолучитьВыводПроцесса("git add --all " + Каталог, КодВозврата);
		Лог.Отладка("Вывод git add: " + Вывод);
		Если КодВозврата <> 0 Тогда
			Лог.Ошибка(Вывод);
			ЗавершитьРаботу(КодВозврата);
		КонецЕсли;
		
	КонецЦикла

КонецПроцедуры

Инициализация();

Если ЗапускВКоманднойСтроке() Тогда
	ЗавершитьРаботу(КодВозврата);
КонецЕсли;


