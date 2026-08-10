/// Every user-facing string in the app, in Persian.
///
/// Views must not hold display text inline — keeping it here is what makes a
/// second locale (or a wording fix) a single-file change.
class AppStrings {
  AppStrings._();

  // ── App ──────────────────────────────────────────────────────────────────
  static const appName = 'رمزسیو';
  static const appTagline = 'گاوصندوق رمزهای شما';
  static const appVersion = '1.0.0';

  // ── Common ───────────────────────────────────────────────────────────────
  static const save = 'ذخیره';
  static const cancel = 'انصراف';
  static const delete = 'حذف';
  static const edit = 'ویرایش';
  static const confirm = 'تأیید';
  static const close = 'بستن';
  static const retry = 'تلاش دوباره';
  static const search = 'جستجو';
  static const viewAll = 'مشاهده همه';
  static const copy = 'کپی';
  static const copied = 'کپی شد';
  static const optional = 'اختیاری';
  static const yes = 'بله';
  static const no = 'خیر';
  static const back = 'بازگشت';
  static const next = 'بعدی';
  static const done = 'انجام شد';
  static const loading = 'در حال بارگذاری…';
  static const noResults = 'چیزی پیدا نشد';

  // ── Splash ───────────────────────────────────────────────────────────────
  static const splashSubtitle = 'رمزهایتان، امن و در دسترس';

  // ── Register (master password setup) ─────────────────────────────────────
  static const registerTitle = 'ساخت رمز اصلی';
  static const registerSubtitle =
      'رمز اصلی کلید ورود به گاوصندوق شماست. آن را در جایی امن نگه دارید — '
      'در صورت فراموشی، امکان بازیابی وجود ندارد.';
  static const yourName = 'نام شما';
  static const yourNameHint = 'مثلاً میلاد نوروزی';
  static const masterPassword = 'رمز اصلی';
  static const masterPasswordHint = 'یک رمز قوی انتخاب کنید';
  static const confirmMasterPassword = 'تکرار رمز اصلی';
  static const confirmMasterPasswordHint = 'رمز اصلی را دوباره وارد کنید';
  static const createVault = 'ساخت گاوصندوق';
  static const registerWarning =
      'هشدار: رمز اصلی فراموش‌شده قابل بازیابی نیست و اطلاعات شما از دست می‌رود.';

  // ── Login (unlock) ───────────────────────────────────────────────────────
  static const loginTitle = 'باز کردن قفل';
  static const loginSubtitle = 'برای دسترسی به گاوصندوق، رمز اصلی را وارد کنید';
  static const unlock = 'باز کردن قفل';
  static const unlockWithBiometric = 'ورود با اثر انگشت یا چهره';
  static const wrongMasterPassword = 'رمز اصلی نادرست است';
  static const welcomeBack = 'خوش آمدید';
  static const forgotMasterPassword = 'رمز اصلی را فراموش کرده‌اید؟';
  static const resetVaultTitle = 'پاک کردن گاوصندوق؟';
  static const resetVaultMessage =
      'رمز اصلی قابل بازیابی نیست، چون هیچ‌جا ذخیره نمی‌شود. تنها راه ادامه، '
      'پاک کردن کامل گاوصندوق و شروع دوباره است. تمام رمزهای ذخیره‌شده برای '
      'همیشه از بین می‌روند.';

  // ── Biometrics ───────────────────────────────────────────────────────────
  static const biometricReason = 'برای باز کردن قفل گاوصندوق احراز هویت کنید';
  static const biometricUnavailable =
      'احراز هویت بیومتریک روی این دستگاه در دسترس نیست';
  static const biometricNotEnrolled =
      'هیچ اثر انگشت یا چهره‌ای روی دستگاه ثبت نشده است';
  static const biometricFailed = 'احراز هویت ناموفق بود';
  static const biometricEnableFirst =
      'برای فعال‌سازی، ابتدا رمز اصلی را وارد کنید';
  static const biometricLockedOut =
      'تلاش‌های ناموفق زیاد بود. کمی بعد دوباره امتحان کنید.';
  static const biometricNoDeviceLock =
      'ابتدا قفل صفحه دستگاه (رمز یا الگو) را فعال کنید';
  static const biometricCancelled = 'احراز هویت لغو شد';
  static const biometricEnabled = 'ورود با بیومتریک فعال شد';
  static const biometricDisabled = 'ورود با بیومتریک غیرفعال شد';

  // ── Home ─────────────────────────────────────────────────────────────────
  static const safetyScore = 'امتیاز امنیت';
  static const topVaults = 'گاوصندوق‌های پربازدید';
  static const categoryBrowser = 'مرورگر';
  static const categoryMobileApp = 'اپلیکیشن';
  static const categoryPayment = 'پرداخت';
  static const emptyVaultTitle = 'هنوز رمزی ذخیره نکرده‌اید';
  static const emptyVaultSubtitle =
      'با دکمه + اولین گاوصندوق خود را بسازید';

  // ── Vault list ───────────────────────────────────────────────────────────
  static const allVaults = 'همه گاوصندوق‌ها';
  static const searchVaultHint = 'جستجو در گاوصندوق‌ها';
  static const filterAll = 'همه';
  static const filterSafe = 'امن';
  static const filterWeak = 'ضعیف';
  static const filterCompromised = 'لو رفته';
  static const filterReused = 'تکراری';
  static const noResultsHint =
      'جستجو یا فیلترها را تغییر دهید تا نتیجه‌ی دیگری ببینید.';
  static const clearFilters = 'پاک کردن فیلترها';

  // ── Add / edit vault ─────────────────────────────────────────────────────
  static const addVaultTitle = 'گاوصندوق جدید';
  static const editVaultTitle = 'ویرایش گاوصندوق';
  static const tabAccount = 'افزودن حساب';
  static const tabPayment = 'افزودن کارت';
  static const serviceName = 'وب‌سایت یا اپلیکیشن';
  static const serviceNameHint = 'مثلاً اینستاگرام';
  static const siteAddress = 'آدرس سایت';
  static const siteAddressHint = 'https://example.com';
  static const login = 'نام کاربری یا ایمیل';
  static const loginHint = 'example@mail.com';
  static const password = 'رمز عبور';
  static const passwordHint = 'رمز عبور را وارد کنید';
  static const note = 'یادداشت';
  static const noteHint = 'یادداشت اختیاری…';
  static const tags = 'برچسب‌ها';
  static const generateStrongPassword = 'ساخت رمز قوی';
  static const createTheVault = 'ساخت گاوصندوق';
  static const saveChanges = 'ذخیره تغییرات';

  // Card fields
  static const cardBrand = 'نوع کارت';
  static const cardHolder = 'نام دارنده کارت';
  static const cardHolderHint = 'همان‌طور که روی کارت درج شده';
  static const cardNumber = 'شماره کارت';
  static const cardNumberHint = '۰۰۰۰ ۰۰۰۰ ۰۰۰۰ ۰۰۰۰';
  static const expiryDate = 'تاریخ انقضا';
  static const expiryHint = 'ماه / سال';
  static const cvv = 'CVV2';
  static const cvvHint = '۰۰۰';

  // ── Vault detail ─────────────────────────────────────────────────────────
  static const changePassword = 'تغییر رمز';
  static const lastUpdated = 'آخرین بروزرسانی';
  static const createdOn = 'ساخته‌شده در';
  static const deleteVaultTitle = 'حذف گاوصندوق؟';
  static const deleteVaultMessage =
      'این گاوصندوق برای همیشه حذف می‌شود. این عمل قابل بازگشت نیست.';
  static const vaultDeleted = 'گاوصندوق حذف شد';
  static const vaultSaved = 'گاوصندوق ذخیره شد';
  static const passwordCopied = 'رمز عبور کپی شد';
  static const loginCopied = 'نام کاربری کپی شد';
  static const clipboardAutoClear = 'کلیپ‌بورد تا ۳۰ ثانیه دیگر پاک می‌شود';
  static const leaksFound = 'مورد نشت پیدا شد';
  static const weakPasswordAdvice =
      'استفاده از رمزهای پیچیده و طولانی شامل نمادها، اعداد و حروف توصیه '
      'می‌شود. از یک رمز برای چند سایت استفاده نکنید.';

  // ── Password generator ───────────────────────────────────────────────────
  static const generatorTitle = 'ساخت رمز امن';
  static const yourNewPassword = 'رمز جدید شما';
  static const passwordLength = 'طول رمز';
  static const options = 'گزینه‌ها';
  static const optLowercase = 'حروف کوچک (a-z)';
  static const optUppercase = 'حروف بزرگ (A-Z)';
  static const optDigits = 'اعداد (۰-۹)';
  static const optSymbols = 'نمادها (#\$%&*)';
  static const optNoAmbiguous = 'حذف نویسه‌های مبهم (l, 1, O, 0)';
  static const savePassword = 'ذخیره رمز';
  static const regenerate = 'ساخت دوباره';
  static const atLeastOneCharSet = 'حداقل یک نوع نویسه باید فعال باشد';

  // ── Password strength ────────────────────────────────────────────────────
  static const strengthVeryWeak = 'خیلی ضعیف';
  static const strengthWeak = 'ضعیف';
  static const strengthGood = 'خوب';
  static const strengthStrong = 'قوی';
  static const strengthLabel = 'قدرت رمز';

  // ── Vault health ─────────────────────────────────────────────────────────
  static const vaultsHealth = 'سلامت گاوصندوق‌ها';
  static const totalVaults = 'کل گاوصندوق‌ها';
  static const safeVaults = 'گاوصندوق‌های امن';
  static const compromisedVaults = 'گاوصندوق‌های لو رفته';
  static const weakVaults = 'گاوصندوق‌های ضعیف';
  static const reusedVaults = 'گاوصندوق‌های تکراری';
  static const vaultsAtRisk = 'گاوصندوق در معرض خطر شناسایی شد';
  static const allHealthy = 'همه گاوصندوق‌ها سالم هستند';
  static const passwordsCount = 'رمز';

  // ── Settings ─────────────────────────────────────────────────────────────
  static const settings = 'تنظیمات';
  static const upgradeToPremium = 'ارتقا به نسخه ویژه';
  static const useBiometric = 'ورود با اثر انگشت یا چهره';
  static const usePasscode = 'قفل با رمز اصلی';
  static const autoLock = 'قفل خودکار';
  static const autoLockImmediately = 'بلافاصله';
  static const autoLockNever = 'هرگز';
  static const personalInfo = 'اطلاعات شخصی';
  static const security = 'امنیت';
  static const backupAndRestore = 'پشتیبان‌گیری و بازیابی';
  static const help = 'راهنما';
  static const privacyPolicy = 'حریم خصوصی';
  static const termsOfUse = 'شرایط استفاده';
  static const logOut = 'قفل کردن گاوصندوق';
  static const about = 'درباره برنامه';
  static const version = 'نسخه';
  static const changeMasterPassword = 'تغییر رمز اصلی';
  static const currentMasterPassword = 'رمز اصلی فعلی';
  static const newMasterPassword = 'رمز اصلی جدید';
  static const masterPasswordChanged = 'رمز اصلی تغییر کرد';
  static const changeMasterPasswordNote =
      'رمزهای ذخیره‌شده دست‌نخورده می‌مانند؛ فقط کلید گاوصندوق با رمز جدید '
      'دوباره محافظت می‌شود. پس از تغییر، برای باز کردن قفل از رمز جدید '
      'استفاده کنید.';
  static const checkBreaches = 'بررسی آنلاین نشت رمزها';
  static const checkBreachesDesc =
      'رمزها هرگز ارسال نمی‌شوند؛ فقط بخشی از اثر انگشت آن‌ها بررسی می‌شود.';
  static const preferences = 'ترجیحات';
  static const dataAndBackup = 'داده‌ها';
  static const aboutDescription =
      'رمزسیو یک گاوصندوق رمز آفلاین است. تمام اطلاعات شما رمزنگاری‌شده روی '
      'همین دستگاه می‌ماند و به هیچ سروری فرستاده نمی‌شود.';
  static const lockVaultNow = 'همین حالا قفل کن';
  static const premiumActive = 'نسخه ویژه فعال است';

  // ── Profile ──────────────────────────────────────────────────────────────
  static const name = 'نام';
  static const email = 'ایمیل';
  static const phone = 'شماره تماس';
  static const profileSaved = 'اطلاعات ذخیره شد';

  // ── Backup ───────────────────────────────────────────────────────────────
  static const exportBackup = 'خروجی گرفتن از گاوصندوق';
  static const importBackup = 'بازیابی از فایل پشتیبان';
  static const backupPassword = 'رمز فایل پشتیبان';
  static const backupPasswordHint = 'رمزی برای محافظت از فایل پشتیبان';
  static const backupExported = 'فایل پشتیبان ساخته شد';
  static const backupImported = 'گاوصندوق بازیابی شد';
  static const backupWrongPassword = 'رمز فایل پشتیبان نادرست است';
  static const backupInvalidFile = 'فایل پشتیبان معتبر نیست';
  static const backupExplain =
      'فایل پشتیبان با رمز جداگانه‌ای که انتخاب می‌کنید رمزنگاری می‌شود. '
      'بدون آن رمز، فایل قابل بازیابی نیست.';
  static const importedCount = 'مورد بازیابی شد';
  static const pickBackupFile = 'انتخاب فایل و بازیابی';
  static const importMergeNote =
      'موارد بازیابی‌شده با گاوصندوق فعلی ادغام می‌شوند؛ چیزی حذف نمی‌شود.';

  // ── Premium ──────────────────────────────────────────────────────────────
  static const premiumTitle = 'ارتقا به نسخه ویژه';
  static const premiumWeekly = 'اشتراک هفتگی';
  static const premiumYearly = 'اشتراک سالانه';
  static const premiumTrial = 'لغو در هر زمان، ۵ روز رایگان';
  static const premiumPerk1 =
      'ساخت و ذخیره نامحدود گاوصندوق در برنامه';
  static const premiumPerk2 =
      'بررسی مداوم حساب‌ها در برابر نشت اطلاعات';
  static const premiumPerk3 = 'حذف کامل تبلیغات از برنامه';
  static const goPremium = 'فعال‌سازی نسخه ویژه';
  static const toman = 'تومان';
  static const perYear = '/ سال';
  static const perWeek = '/ هفته';
  static const premiumDemoNote =
      'این صفحه نمایشی است و به درگاه پرداخت واقعی متصل نیست.';

  // ── Validation ───────────────────────────────────────────────────────────
  static const fieldRequired = 'این فیلد الزامی است';
  static const passwordTooShort = 'رمز اصلی باید حداقل ۸ نویسه باشد';
  static const passwordsDoNotMatch = 'رمزها با هم مطابقت ندارند';
  static const sameAsCurrentPassword =
      'رمز جدید باید با رمز فعلی متفاوت باشد';
  static const invalidEmail = 'ایمیل معتبر نیست';
  static const invalidUrl = 'آدرس معتبر نیست';
  static const invalidCardNumber = 'شماره کارت معتبر نیست';
  static const invalidExpiry = 'تاریخ انقضا معتبر نیست';
  static const invalidCvv = 'CVV2 معتبر نیست';
  static const invalidPhone = 'شماره تماس معتبر نیست';

  // ── Errors ───────────────────────────────────────────────────────────────
  static const genericError = 'خطایی رخ داد. دوباره تلاش کنید.';
  static const storageError = 'خطا در دسترسی به حافظه امن دستگاه';

  // ── Time ─────────────────────────────────────────────────────────────────
  static const justNow = 'همین الان';
  static const minutesAgo = 'دقیقه پیش';
  static const hoursAgo = 'ساعت پیش';
  static const daysAgo = 'روز پیش';
  static const monthsAgo = 'ماه پیش';
  static const yearsAgo = 'سال پیش';
  static const minute = 'دقیقه';
}
