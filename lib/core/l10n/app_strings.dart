enum AppLocale { en, ru }

class AppStrings {
  final AppLocale locale;

  const AppStrings(this.locale);

  bool get _ru => locale == AppLocale.ru;

  String get appTitle => _ru ? 'Мои финансы' : 'My Finances';
  String get totalBalance => _ru ? 'ОБЩИЙ БАЛАНС' : 'TOTAL BALANCE';
  String get tapAndHoldToEdit =>
      _ru ? 'удерживайте для редактирования' : 'tap and hold to edit';
  String get addAccount => _ru ? 'Добавить счёт' : 'Add account';
  String get addTransactionDashboard => _ru ? 'Добавить' : 'Add';
  String get transactions => _ru ? 'Транзакции' : 'Transactions';
  String get searchHint =>
      _ru ? 'Поиск транзакций...' : 'Search transactions...';
  String get filterAll => _ru ? 'Все' : 'All';
  String get filterIncome => _ru ? 'Доход' : 'Income';
  String get filterExpense => _ru ? 'Расход' : 'Expense';
  String get filterTransfer => _ru ? 'Перевод' : 'Transfer';
  String get filterAllTime => _ru ? 'Всё время' : 'All Time';
  String get filterMonth => _ru ? 'Месяц' : 'Month';
  String get income => _ru ? 'Доход' : 'Income';
  String get expenses => _ru ? 'Расходы' : 'Expenses';
  String get monthlyBudget => _ru ? 'Бюджет на месяц' : 'Monthly Budget';
  String get spent => _ru ? 'Потрачено' : 'Spent';
  String get limit => _ru ? 'Лимит' : 'Limit';
  String get noTransactions =>
      _ru ? 'Транзакции не найдены' : 'No transactions found';
  String get addFirstTx => _ru
      ? 'Нажмите + чтобы добавить первую транзакцию'
      : 'Tap + to add your first transaction';

  String get addTransaction => _ru ? 'Новая транзакция' : 'Add Transaction';
  String get editTransaction => _ru ? 'Редактировать' : 'Edit Transaction';
  String get amount => _ru ? 'Сумма' : 'Amount';
  String get category => _ru ? 'Категория' : 'Category';
  String get note => _ru ? 'Заметка' : 'Note';
  String get date => _ru ? 'Дата' : 'Date';
  String get time => _ru ? 'Время' : 'Time';
  String get save => _ru ? 'Сохранить' : 'Save';
  String get delete => _ru ? 'Удалить' : 'Delete';
  String get cancel => _ru ? 'Отмена' : 'Cancel';
  String get typeIncome => _ru ? 'Доход' : 'Income';
  String get typeExpense => _ru ? 'Расход' : 'Expense';
  String get confirmDelete =>
      _ru ? 'Удалить транзакцию?' : 'Delete transaction?';
  String get confirmDeleteBody =>
      _ru ? 'Это действие нельзя отменить.' : 'This action cannot be undone.';
  String get saveChanges => _ru ? 'Сохранить изменения' : 'Save Changes';
  String get noteOptional =>
      _ru ? 'Заметка (необязательно)' : 'Note (optional)';
  String get addNote => _ru ? 'Добавить заметку...' : 'Add a note...';

  String get settings => _ru ? 'Настройки' : 'Settings';
  String get managePreferences =>
      _ru ? 'Управление настройками' : 'Manage your preferences';
  String get appearance => _ru ? 'Внешний вид' : 'Appearance';
  String get theme => _ru ? 'Тема' : 'Theme';
  String get themeDark => _ru ? 'Тёмная' : 'Dark';
  String get themeLight => _ru ? 'Светлая' : 'Light';
  String get themeSystem => _ru ? 'Системная' : 'System';
  String get cardTextColor => _ru ? 'Цвет текста карточки' : 'Card text color';
  String get cardTextColorWhite => _ru ? 'Белый' : 'White';
  String get cardTextColorAdaptive => _ru ? 'Авто' : 'Adaptive';
  String get cardTextColorBlack => _ru ? 'Чёрный' : 'Black';
  String get darkMode => _ru ? 'Тёмная тема' : 'Dark Mode';
  String get enabled => _ru ? 'Включено' : 'Enabled';
  String get disabled => _ru ? 'Выключено' : 'Disabled';
  String get hapticFeedback => _ru ? 'Тактильная отдача' : 'Haptic Feedback';
  String get vibrationOnInteractions =>
      _ru ? 'Вибрация при взаимодействии' : 'Vibration on interactions';
  String get biometricLock => _ru ? 'Биометрия' : 'Biometric Lock';
  String get requireFingerprint =>
      _ru ? 'Отпечаток при запуске' : 'Require fingerprint to unlock';
  String get currency => _ru ? 'Валюта' : 'Currency';
  String get amountFormat => _ru ? 'Формат суммы' : 'Amount Format';
  String get language => _ru ? 'Язык' : 'Language';
  String get langRu => _ru ? 'Русский' : 'Russian';
  String get langEn => _ru ? 'Английский' : 'English';
  String get budget => _ru ? 'Бюджет' : 'Budget';
  String get budgetHint => _ru ? 'Месячный лимит' : 'Monthly limit';
  String get budgetNone => _ru ? 'Не установлен' : 'Not set';
  String get monthlyBudgetSetting => _ru ? 'Месячный бюджет' : 'Monthly Budget';
  String get yourMonthlySpendingLimit =>
      _ru ? 'Ваш лимит расходов на месяц' : 'Your monthly spending limit';
  String get setMonthlySpendingLimit => _ru
      ? 'Контролируйте свои расходы за месяц'
      : 'Track your monthly spending';
  String get leaveEmptyToRemove => _ru
      ? 'Оставьте пустым для удаления лимита'
      : 'Leave empty to remove budget limit';
  String get data => _ru ? 'Данные' : 'Data';
  String get exportData => _ru ? 'Экспорт данных' : 'Export data';
  String get clearData => _ru ? 'Очистить данные' : 'Clear all data';
  String get clearAllTransactions =>
      _ru ? 'Удалить транзакции' : 'Clear All Transactions';
  String get clearDataConfirm =>
      _ru ? 'Удалить транзакции?' : 'Clear all transactions?';
  String get clearDataWarning => _ru
      ? 'Это навсегда удалит всю историю транзакций. Это действие нельзя отменить.'
      : 'This will permanently delete all your transaction history. This cannot be undone.';
  String get areYouSure =>
      _ru ? 'Вы абсолютно уверены?' : 'Are you absolutely sure?';
  String get allTransactionsDeleted =>
      _ru ? 'Все транзакции удалены' : 'All transactions deleted';
  String get noKeepThem => _ru ? 'Нет, оставить' : 'No, keep them';
  String get yesDeleteEverything =>
      _ru ? 'Да, удалить всё' : 'Yes, delete everything';
  String get allTransactionsWillBeDeleted => _ru
      ? 'Все транзакции будут удалены навсегда. Восстановить их будет невозможно.'
      : 'All transactions will be deleted forever. There is no way to recover them.';
  String get dangerZone => _ru ? 'Опасная зона' : 'Danger Zone';

  String get navDashboard => _ru ? 'Главная' : 'Dashboard';
  String get navCategories => _ru ? 'Статистика' : 'Statistics';
  String get navSettings => _ru ? 'Настройки' : 'Settings';

  String get statistics => _ru ? 'Статистика' : 'Statistics';
  String get allAccounts => _ru ? 'Все счета' : 'All accounts';
  String get categories => _ru ? 'Категории' : 'Categories';
  String get rankedByAmount => _ru ? 'По сумме' : 'Ranked by Amount';
  String get overview => _ru ? 'Обзор' : 'Overview';
  String get netBalance => _ru ? 'Чистый баланс' : 'Net Balance';
  String get averageIncome => _ru ? 'Средний доход' : 'Average Income';
  String get averageExpense => _ru ? 'Средний расход' : 'Average Expense';
  String get transactionsCount => _ru ? 'Транзакции' : 'Transactions';
  String get expenseStructure => _ru ? 'Структура категорий' : 'Category Structure';
  String get topCategories => _ru ? 'Топ категорий' : 'Top Categories';
  String get monthlyTrend => _ru ? 'Тренд по месяцам' : 'Monthly Trend';
  String get topCategory => _ru ? 'Лидер категории' : 'Top Category';
  String get shareOfTotal => _ru ? 'Доля от общего' : 'Share of Total';
  String get thisPeriod => _ru ? 'За период' : 'This Period';
  String get analyticsInsight => _ru ? 'Финансовый срез по выбранному диапазону и счёту' : 'Financial snapshot for the selected range and account';
  String get noStatisticsYet => _ru ? 'Пока недостаточно данных' : 'Not enough data yet';
  String get statisticsWillAppear => _ru ? 'Когда появятся операции, здесь будет красивый аналитический обзор' : 'Once you add transactions, a beautiful analytics overview will appear here';
  String get addCategory => _ru ? 'Добавить категорию' : 'Add Category';
  String get editCategory => _ru ? 'Редактировать' : 'Edit Category';
  String get categoryName => _ru ? 'Название' : 'Name';
  String get categoryIcon => _ru ? 'Иконка' : 'Icon';
  String get categoryColor => _ru ? 'Цвет' : 'Color';
  String get deleteCategory => _ru ? 'Удалить категорию' : 'Delete Category';
  String get noCategoriesYet => _ru ? 'Нет категорий' : 'No categories yet';
  String get noExpenseData => _ru ? 'Нет данных о расходах' : 'No expense data';
  String get addExpensesToSeeBreakdown => _ru
      ? 'Добавьте расходы, чтобы увидеть разбивку'
      : 'Add some expenses to see the breakdown';
  String get noIncomeData => _ru ? 'Нет данных о доходах' : 'No income data';
  String get addIncomeToSeeBreakdown => _ru
      ? 'Добавьте доходы, чтобы увидеть разбивку'
      : 'Add some income to see the breakdown';
  String get total => _ru ? 'Всего' : 'Total';
  String get lastSixMonths => _ru ? 'Последние 6 месяцев' : 'Last 6 Months';

  String categoryLabel(String key) {
    if (!_ru) return key;
    const map = {
      'Food': 'Еда',
      'Transport': 'Транспорт',
      'Shopping': 'Покупки',
      'Entertainment': 'Развлечения',
      'Health': 'Здоровье',
      'Housing': 'Жильё',
      'Education': 'Образование',
      'Travel': 'Путешествия',
      'Salary': 'Зарплата',
      'Freelance': 'Фриланс',
      'Investment': 'Инвестиции',
      'Gift': 'Подарок',
      'Refund': 'Возврат',
      'Other': 'Другое',
      'Utilities': 'Коммунальные',
      'Clothing': 'Одежда',
      'Sports': 'Спорт',
      'Beauty': 'Красота',
      'Pets': 'Питомцы',
      'Business': 'Бизнес',
      'Savings': 'Накопления',
    };
    return map[key] ?? key;
  }

  String get colorPrimary => _ru ? 'Основной' : 'Primary';
  String get colorSecondary => _ru ? 'Второй' : 'Secondary';
  String get colorSecond => _ru ? 'Второй' : 'Second';
  String get colorSolid => _ru ? 'Однотон' : 'Solid';
  String get gradientLinear => _ru ? 'Линейный' : 'Linear';
  String get gradientReverse => _ru ? 'Обратный' : 'Reverse';
  String get gradientRadial => _ru ? 'Радиус' : 'Radial';
  String get gradientSweep => _ru ? 'Круговой' : 'Sweep';
  String get reset => _ru ? 'Сброс' : 'Reset';
  String get apply => _ru ? 'Применить' : 'Apply';

  String get accountsInfoTitle => _ru ? 'Счета' : 'Accounts';
  String get accountsInfoBalance => _ru
      ? 'У каждого счёта свой баланс, валюта и цвет карточки.'
      : 'Each account has its own balance, currency and card color.';
  String get accountsInfoCustomize => _ru
      ? 'Удерживайте карточку для настройки градиента, названия и валюты.'
      : 'Long-press any card to customize its gradient, name and currency.';
  String get accountsInfoLimit =>
      _ru ? 'Максимум 5 счетов.' : 'Maximum 5 accounts.';

  String get currencyConversions =>
      _ru ? 'Конвертация валют' : 'Currency conversions';
  String get showConversionsOnCard =>
      _ru ? 'Показывать на карточке' : 'Show on balance card';

  String get selectSourceAccount =>
      _ru ? 'Выберите счёт отправителя' : 'Select source account';
  String get selectDestAccount =>
      _ru ? 'Выберите счёт получателя' : 'Select destination account';
  String get accountsMustDiffer =>
      _ru ? 'Счета должны отличаться' : 'Accounts must differ';
  String get transferLabel => _ru ? 'Перевод' : 'Transfer';
  String get transferTo => _ru ? 'на' : 'to';
  String get transferFrom => _ru ? 'с' : 'from';
  String get selectAccount => _ru ? 'Выберите счёт' : 'Select account';
  String get accountPlaceholder => _ru ? 'Счёт' : 'Account';
  String get saveError => _ru ? 'Ошибка сохранения' : 'Save error';

  String get manageCategories => _ru ? 'Категории' : 'Categories';
  String get manageCategoriesSubtitle => _ru
      ? 'Создавайте и редактируйте свои категории'
      : 'Create and edit your own categories';
  String get customCategories => _ru ? 'Свои категории' : 'Custom categories';
  String get defaultCategories =>
      _ru ? 'Стандартные категории' : 'Default categories';
  String get newCategory => _ru ? 'Новая категория' : 'New category';
  String get nameEn => _ru ? 'Название (EN)' : 'Name (EN)';
  String get nameRu => _ru ? 'Название (RU)' : 'Name (RU)';
  String get nameEnHint => _ru ? 'Например, Coffee' : 'e.g. Coffee';
  String get nameRuHint => _ru ? 'Например, Кофе' : 'e.g. Кофе';
  String get autoTranslate => _ru ? 'Автоперевод' : 'Auto-translate';
  String get applyTranslation => _ru ? 'Применить' : 'Apply';
  String get translating => _ru ? 'Перевод...' : 'Translating...';
  String get translationFailed =>
      _ru ? 'Не удалось перевести' : 'Translation failed';
  String get categoryNameRequired =>
      _ru ? 'Введите название' : 'Enter a name';
  String get deleteCategoryConfirm =>
      _ru ? 'Удалить эту категорию?' : 'Delete this category?';
  String get deleteCategoryWarning => _ru
      ? 'Категория будет удалена. Прошлые транзакции сохранятся.'
      : 'The category will be removed. Past transactions are kept.';
  String get noCustomCategories =>
      _ru ? 'Вы ещё не добавили категории' : 'No custom categories yet';
  String get noCustomCategoriesHint => _ru
      ? 'Нажмите +, чтобы создать свою категорию'
      : 'Tap + to create your own category';
  String get categoryType => _ru ? 'Тип' : 'Type';
  String get categorySaved => _ru ? 'Категория сохранена' : 'Category saved';

  String get dateLocale => _ru ? 'ru_RU' : 'en_US';
}
