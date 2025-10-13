import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @personalityHumorous.
  ///
  /// In en, this message translates to:
  /// **'Humorous'**
  String get personalityHumorous;

  /// No description provided for @personalitySerious.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get personalitySerious;

  /// No description provided for @personalityEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get personalityEnergetic;

  /// No description provided for @personalityCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get personalityCalm;

  /// No description provided for @personalityConsiderate.
  ///
  /// In en, this message translates to:
  /// **'Considerate'**
  String get personalityConsiderate;

  /// No description provided for @personalityHonest.
  ///
  /// In en, this message translates to:
  /// **'Honest'**
  String get personalityHonest;

  /// No description provided for @personalityPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get personalityPositive;

  /// No description provided for @personalityThoughtful.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful'**
  String get personalityThoughtful;

  /// No description provided for @personalityPassionate.
  ///
  /// In en, this message translates to:
  /// **'Passionate'**
  String get personalityPassionate;

  /// No description provided for @personalityRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get personalityRelaxed;

  /// No description provided for @personalityIntellectual.
  ///
  /// In en, this message translates to:
  /// **'Intellectual'**
  String get personalityIntellectual;

  /// No description provided for @personalityEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get personalityEmotional;

  /// No description provided for @personalityRealistic.
  ///
  /// In en, this message translates to:
  /// **'Realistic'**
  String get personalityRealistic;

  /// No description provided for @personalityCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get personalityCreative;

  /// No description provided for @personalityOrganized.
  ///
  /// In en, this message translates to:
  /// **'Organized'**
  String get personalityOrganized;

  /// No description provided for @personalitySpontaneous.
  ///
  /// In en, this message translates to:
  /// **'Spontaneous'**
  String get personalitySpontaneous;

  /// No description provided for @othersFunny.
  ///
  /// In en, this message translates to:
  /// **'Funny'**
  String get othersFunny;

  /// No description provided for @othersKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get othersKind;

  /// No description provided for @othersCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get othersCool;

  /// No description provided for @othersPretty.
  ///
  /// In en, this message translates to:
  /// **'Pretty'**
  String get othersPretty;

  /// No description provided for @othersSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get othersSmart;

  /// No description provided for @othersSensible.
  ///
  /// In en, this message translates to:
  /// **'Sensible'**
  String get othersSensible;

  /// No description provided for @othersGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get othersGentle;

  /// No description provided for @othersChill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get othersChill;

  /// No description provided for @othersCute.
  ///
  /// In en, this message translates to:
  /// **'Cute'**
  String get othersCute;

  /// No description provided for @othersReliable.
  ///
  /// In en, this message translates to:
  /// **'Reliable'**
  String get othersReliable;

  /// No description provided for @othersComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get othersComfortable;

  /// No description provided for @othersCharming.
  ///
  /// In en, this message translates to:
  /// **'Charming'**
  String get othersCharming;

  /// No description provided for @othersTrustworthy.
  ///
  /// In en, this message translates to:
  /// **'Trustworthy'**
  String get othersTrustworthy;

  /// No description provided for @othersLeadership.
  ///
  /// In en, this message translates to:
  /// **'Leadership'**
  String get othersLeadership;

  /// No description provided for @idealHumor.
  ///
  /// In en, this message translates to:
  /// **'Sense of humor'**
  String get idealHumor;

  /// No description provided for @idealSeriousness.
  ///
  /// In en, this message translates to:
  /// **'Seriousness'**
  String get idealSeriousness;

  /// No description provided for @idealEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get idealEnergy;

  /// No description provided for @idealCalmness.
  ///
  /// In en, this message translates to:
  /// **'Calmness'**
  String get idealCalmness;

  /// No description provided for @idealConversation.
  ///
  /// In en, this message translates to:
  /// **'Good conversation'**
  String get idealConversation;

  /// No description provided for @idealConsideration.
  ///
  /// In en, this message translates to:
  /// **'Consideration'**
  String get idealConsideration;

  /// No description provided for @idealPassion.
  ///
  /// In en, this message translates to:
  /// **'Passion'**
  String get idealPassion;

  /// No description provided for @idealRelaxation.
  ///
  /// In en, this message translates to:
  /// **'Relaxation'**
  String get idealRelaxation;

  /// No description provided for @idealHonesty.
  ///
  /// In en, this message translates to:
  /// **'Honesty'**
  String get idealHonesty;

  /// No description provided for @idealPositivity.
  ///
  /// In en, this message translates to:
  /// **'Positivity'**
  String get idealPositivity;

  /// No description provided for @idealIntellect.
  ///
  /// In en, this message translates to:
  /// **'Intellect'**
  String get idealIntellect;

  /// No description provided for @idealEmotion.
  ///
  /// In en, this message translates to:
  /// **'Emotion'**
  String get idealEmotion;

  /// No description provided for @idealPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get idealPlanning;

  /// No description provided for @idealSpontaneity.
  ///
  /// In en, this message translates to:
  /// **'Spontaneity'**
  String get idealSpontaneity;

  /// No description provided for @idealLeadership.
  ///
  /// In en, this message translates to:
  /// **'Leadership'**
  String get idealLeadership;

  /// No description provided for @idealEmpathy.
  ///
  /// In en, this message translates to:
  /// **'Empathy'**
  String get idealEmpathy;

  /// No description provided for @dateActiveActivities.
  ///
  /// In en, this message translates to:
  /// **'Active activities'**
  String get dateActiveActivities;

  /// No description provided for @dateRelaxedWalk.
  ///
  /// In en, this message translates to:
  /// **'Relaxed walk'**
  String get dateRelaxedWalk;

  /// No description provided for @dateFoodTour.
  ///
  /// In en, this message translates to:
  /// **'Food tour'**
  String get dateFoodTour;

  /// No description provided for @dateCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe date'**
  String get dateCafe;

  /// No description provided for @dateCulture.
  ///
  /// In en, this message translates to:
  /// **'Cultural activities'**
  String get dateCulture;

  /// No description provided for @dateHomeRelax.
  ///
  /// In en, this message translates to:
  /// **'Relax at home'**
  String get dateHomeRelax;

  /// No description provided for @dateDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get dateDrive;

  /// No description provided for @dateExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get dateExercise;

  /// No description provided for @dateMovieShow.
  ///
  /// In en, this message translates to:
  /// **'Movies/Shows'**
  String get dateMovieShow;

  /// No description provided for @dateShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get dateShopping;

  /// No description provided for @dateHealing.
  ///
  /// In en, this message translates to:
  /// **'Healing'**
  String get dateHealing;

  /// No description provided for @dateNewExperience.
  ///
  /// In en, this message translates to:
  /// **'New experiences'**
  String get dateNewExperience;

  /// No description provided for @drinkingNone.
  ///
  /// In en, this message translates to:
  /// **'Don\'t drink'**
  String get drinkingNone;

  /// No description provided for @drinkingSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get drinkingSometimes;

  /// No description provided for @drinkingOften.
  ///
  /// In en, this message translates to:
  /// **'Often'**
  String get drinkingOften;

  /// No description provided for @drinkingSocial.
  ///
  /// In en, this message translates to:
  /// **'Social drinker'**
  String get drinkingSocial;

  /// No description provided for @smokingNonSmoker.
  ///
  /// In en, this message translates to:
  /// **'Non-smoker'**
  String get smokingNonSmoker;

  /// No description provided for @smokingSmoker.
  ///
  /// In en, this message translates to:
  /// **'Smoker'**
  String get smokingSmoker;

  /// No description provided for @jobUnemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get jobUnemployed;

  /// No description provided for @jobIT.
  ///
  /// In en, this message translates to:
  /// **'IT/Tech'**
  String get jobIT;

  /// No description provided for @jobFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance/Banking'**
  String get jobFinance;

  /// No description provided for @jobMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical/Healthcare'**
  String get jobMedical;

  /// No description provided for @jobEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get jobEducation;

  /// No description provided for @jobDesign.
  ///
  /// In en, this message translates to:
  /// **'Design/Arts'**
  String get jobDesign;

  /// No description provided for @jobMedia.
  ///
  /// In en, this message translates to:
  /// **'Media/Entertainment'**
  String get jobMedia;

  /// No description provided for @jobService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get jobService;

  /// No description provided for @jobManufacturing.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing'**
  String get jobManufacturing;

  /// No description provided for @jobConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction/Real Estate'**
  String get jobConstruction;

  /// No description provided for @jobRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail/Sales'**
  String get jobRetail;

  /// No description provided for @jobPublic.
  ///
  /// In en, this message translates to:
  /// **'Public Sector'**
  String get jobPublic;

  /// No description provided for @jobLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal/Law'**
  String get jobLegal;

  /// No description provided for @jobResearch.
  ///
  /// In en, this message translates to:
  /// **'Research/Development'**
  String get jobResearch;

  /// No description provided for @jobFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get jobFreelance;

  /// No description provided for @jobBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business/Startup'**
  String get jobBusiness;

  /// No description provided for @jobStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get jobStudent;

  /// No description provided for @jobOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get jobOther;

  /// No description provided for @interestMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies/Drama'**
  String get interestMovies;

  /// No description provided for @interestMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get interestMusic;

  /// No description provided for @interestReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get interestReading;

  /// No description provided for @interestTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get interestTravel;

  /// No description provided for @interestExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get interestExercise;

  /// No description provided for @interestCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get interestCooking;

  /// No description provided for @interestPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get interestPhotography;

  /// No description provided for @interestGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get interestGaming;

  /// No description provided for @interestCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get interestCafe;

  /// No description provided for @interestFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get interestFood;

  /// No description provided for @interestShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get interestShopping;

  /// No description provided for @interestExhibitions.
  ///
  /// In en, this message translates to:
  /// **'Exhibitions'**
  String get interestExhibitions;

  /// No description provided for @interestConcerts.
  ///
  /// In en, this message translates to:
  /// **'Concerts'**
  String get interestConcerts;

  /// No description provided for @interestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get interestSports;

  /// No description provided for @interestHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get interestHiking;

  /// No description provided for @interestBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get interestBeach;

  /// No description provided for @interestPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get interestPets;

  /// No description provided for @interestAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get interestAlcohol;

  /// No description provided for @interestCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get interestCoffee;

  /// No description provided for @interestDesserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get interestDesserts;

  /// No description provided for @interestFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get interestFashion;

  /// No description provided for @interestBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get interestBeauty;

  /// No description provided for @interestCars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get interestCars;

  /// No description provided for @interestMotorcycles.
  ///
  /// In en, this message translates to:
  /// **'Motorcycles'**
  String get interestMotorcycles;

  /// No description provided for @interestDancing.
  ///
  /// In en, this message translates to:
  /// **'Dancing'**
  String get interestDancing;

  /// No description provided for @interestKaraoke.
  ///
  /// In en, this message translates to:
  /// **'Karaoke'**
  String get interestKaraoke;

  /// No description provided for @interestInstruments.
  ///
  /// In en, this message translates to:
  /// **'Playing instruments'**
  String get interestInstruments;

  /// No description provided for @interestDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get interestDrawing;

  /// No description provided for @interestCrafts.
  ///
  /// In en, this message translates to:
  /// **'Crafts'**
  String get interestCrafts;

  /// No description provided for @interestBaking.
  ///
  /// In en, this message translates to:
  /// **'Baking'**
  String get interestBaking;

  /// No description provided for @interestWine.
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get interestWine;

  /// No description provided for @interestBeer.
  ///
  /// In en, this message translates to:
  /// **'Beer'**
  String get interestBeer;

  /// No description provided for @interestCocktails.
  ///
  /// In en, this message translates to:
  /// **'Cocktails'**
  String get interestCocktails;

  /// No description provided for @interestHomeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Home workout'**
  String get interestHomeWorkout;

  /// No description provided for @interestYogaPilates.
  ///
  /// In en, this message translates to:
  /// **'Yoga/Pilates'**
  String get interestYogaPilates;

  /// No description provided for @interestSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get interestSwimming;

  /// No description provided for @interestClimbing.
  ///
  /// In en, this message translates to:
  /// **'Climbing'**
  String get interestClimbing;

  /// No description provided for @interestGolf.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get interestGolf;

  /// No description provided for @interestTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get interestTennis;

  /// No description provided for @interestBadminton.
  ///
  /// In en, this message translates to:
  /// **'Badminton'**
  String get interestBadminton;

  /// No description provided for @interestSoccer.
  ///
  /// In en, this message translates to:
  /// **'Soccer'**
  String get interestSoccer;

  /// No description provided for @interestBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get interestBasketball;

  /// No description provided for @interestBaseball.
  ///
  /// In en, this message translates to:
  /// **'Baseball'**
  String get interestBaseball;

  /// No description provided for @interestRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get interestRunning;

  /// No description provided for @interestCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get interestCycling;

  /// No description provided for @interestCamping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get interestCamping;

  /// No description provided for @interestFishing.
  ///
  /// In en, this message translates to:
  /// **'Fishing'**
  String get interestFishing;

  /// No description provided for @interestSurfing.
  ///
  /// In en, this message translates to:
  /// **'Surfing'**
  String get interestSurfing;

  /// No description provided for @interestSkiSnowboard.
  ///
  /// In en, this message translates to:
  /// **'Ski/Snowboard'**
  String get interestSkiSnowboard;

  /// No description provided for @interestDiving.
  ///
  /// In en, this message translates to:
  /// **'Diving'**
  String get interestDiving;

  /// No description provided for @interestDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get interestDriving;

  /// No description provided for @locationSeoul.
  ///
  /// In en, this message translates to:
  /// **'Seoul'**
  String get locationSeoul;

  /// No description provided for @locationIncheon.
  ///
  /// In en, this message translates to:
  /// **'Incheon'**
  String get locationIncheon;

  /// No description provided for @locationGyeonggiSouth.
  ///
  /// In en, this message translates to:
  /// **'Southern Gyeonggi'**
  String get locationGyeonggiSouth;

  /// No description provided for @locationGyeonggiNorth.
  ///
  /// In en, this message translates to:
  /// **'Northern Gyeonggi'**
  String get locationGyeonggiNorth;

  /// No description provided for @locationGangwon.
  ///
  /// In en, this message translates to:
  /// **'Gangwon'**
  String get locationGangwon;

  /// No description provided for @locationChungbuk.
  ///
  /// In en, this message translates to:
  /// **'Chungcheongbuk'**
  String get locationChungbuk;

  /// No description provided for @locationChungnam.
  ///
  /// In en, this message translates to:
  /// **'Chungcheongnam'**
  String get locationChungnam;

  /// No description provided for @locationGyeongbuk.
  ///
  /// In en, this message translates to:
  /// **'Gyeongsangbuk'**
  String get locationGyeongbuk;

  /// No description provided for @locationGyeongnam.
  ///
  /// In en, this message translates to:
  /// **'Gyeongsangnam'**
  String get locationGyeongnam;

  /// No description provided for @locationJeonbuk.
  ///
  /// In en, this message translates to:
  /// **'Jeonrabuk'**
  String get locationJeonbuk;

  /// No description provided for @locationJeonnam.
  ///
  /// In en, this message translates to:
  /// **'Jeonranam'**
  String get locationJeonnam;

  /// No description provided for @locationJeju.
  ///
  /// In en, this message translates to:
  /// **'Jeju'**
  String get locationJeju;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hearty'**
  String get appName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @matchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Match'**
  String get matchingTitle;

  /// No description provided for @matchingLoading.
  ///
  /// In en, this message translates to:
  /// **'Finding your special connection today...'**
  String get matchingLoading;

  /// No description provided for @matchingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading match information'**
  String get matchingError;

  /// No description provided for @matchingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new matches today'**
  String get matchingEmpty;

  /// No description provided for @matchingEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll introduce someone new tomorrow!\nNew matches are revealed daily at 12 PM.'**
  String get matchingEmptyDesc;

  /// No description provided for @matchingNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match in'**
  String get matchingNextMatch;

  /// No description provided for @matchingReady.
  ///
  /// In en, this message translates to:
  /// **'Today\'s match is ready!'**
  String get matchingReady;

  /// No description provided for @matchingReadyTime.
  ///
  /// In en, this message translates to:
  /// **'Revealed at 12 PM'**
  String get matchingReadyTime;

  /// No description provided for @matchingReadyDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} special connection(s) waiting for you.\nRevealed at 12 PM.'**
  String matchingReadyDesc(int count);

  /// No description provided for @matchingLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked!'**
  String get matchingLiked;

  /// No description provided for @matchingPassed.
  ///
  /// In en, this message translates to:
  /// **'See you next time'**
  String get matchingPassed;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading chat list...'**
  String get chatLoading;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatEmpty;

  /// No description provided for @chatEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'When you both like each other,\nyou can start chatting!'**
  String get chatEmptyDesc;

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatPlaceholder;

  /// No description provided for @chatFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Send your first message!'**
  String get chatFirstMessage;

  /// No description provided for @chatFirstMessageDesc.
  ///
  /// In en, this message translates to:
  /// **'You both liked each other - it\'s a special connection.\nStart the conversation naturally!'**
  String get chatFirstMessageDesc;

  /// No description provided for @chatWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get chatWeekdaySun;

  /// No description provided for @chatWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get chatWeekdayMon;

  /// No description provided for @chatWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get chatWeekdayTue;

  /// No description provided for @chatWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get chatWeekdayWed;

  /// No description provided for @chatWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get chatWeekdayThu;

  /// No description provided for @chatWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get chatWeekdayFri;

  /// No description provided for @chatWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get chatWeekdaySat;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile information'**
  String get profileError;

  /// No description provided for @profileNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNickname;

  /// No description provided for @profileNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get profileNicknameHint;

  /// No description provided for @profileNicknameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get profileNicknameError;

  /// No description provided for @profileNicknameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be at least 2 characters'**
  String get profileNicknameMinLength;

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBio;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself attractively (at least 50 characters)'**
  String get profileBioHint;

  /// No description provided for @profileBioError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your bio'**
  String get profileBioError;

  /// No description provided for @profileBioMinLength.
  ///
  /// In en, this message translates to:
  /// **'Bio must be at least 50 characters'**
  String get profileBioMinLength;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileGenderError.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get profileGenderError;

  /// No description provided for @profileBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get profileBirthday;

  /// No description provided for @profileBirthdayError.
  ///
  /// In en, this message translates to:
  /// **'Please select your birthday'**
  String get profileBirthdayError;

  /// No description provided for @profileAgeError.
  ///
  /// In en, this message translates to:
  /// **'Age must be between 18-80'**
  String get profileAgeError;

  /// No description provided for @profileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocation;

  /// No description provided for @profileLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileLocationHint;

  /// No description provided for @profileJobCategory.
  ///
  /// In en, this message translates to:
  /// **'Job Category'**
  String get profileJobCategory;

  /// No description provided for @profileJobCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileJobCategoryHint;

  /// No description provided for @profileDrinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get profileDrinking;

  /// No description provided for @profileDrinkingHint.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get profileDrinkingHint;

  /// No description provided for @profileSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get profileSmoking;

  /// No description provided for @profileSmokingHint.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get profileSmokingHint;

  /// No description provided for @profilePhotos.
  ///
  /// In en, this message translates to:
  /// **'Profile Photos'**
  String get profilePhotos;

  /// No description provided for @profilePhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get profilePhotoAdd;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoMaxError.
  ///
  /// In en, this message translates to:
  /// **'You can upload up to 3 photos'**
  String get profilePhotoMaxError;

  /// No description provided for @profileBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get profileBasicInfo;

  /// No description provided for @profilePersonalityTitle.
  ///
  /// In en, this message translates to:
  /// **'My Personality/Appeal'**
  String get profilePersonalityTitle;

  /// No description provided for @profilePersonalitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select up to 5'**
  String get profilePersonalitySubtitle;

  /// No description provided for @profilePersonalityCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}/5'**
  String profilePersonalityCount(int count);

  /// No description provided for @profileOthersSayTitle.
  ///
  /// In en, this message translates to:
  /// **'What Others Say About Me'**
  String get profileOthersSayTitle;

  /// No description provided for @profileOthersSaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select up to 3'**
  String get profileOthersSaySubtitle;

  /// No description provided for @profileOthersSayCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}/3'**
  String profileOthersSayCount(int count);

  /// No description provided for @profileIdealTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ideal Type/Desired Style'**
  String get profileIdealTypeTitle;

  /// No description provided for @profileIdealTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select up to 5'**
  String get profileIdealTypeSubtitle;

  /// No description provided for @profileIdealTypeCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}/5'**
  String profileIdealTypeCount(int count);

  /// No description provided for @authApprovalWaiting.
  ///
  /// In en, this message translates to:
  /// **'Profile Review in Progress'**
  String get authApprovalWaiting;

  /// No description provided for @authApprovalWaitingDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing all profiles for safe connections.\nYou\'ll receive a notification when approved!'**
  String get authApprovalWaitingDesc;

  /// No description provided for @authApprovalCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Approval Status'**
  String get authApprovalCheckStatus;

  /// No description provided for @authApprovalChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get authApprovalChecking;

  /// No description provided for @dashboardNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get dashboardNews;

  /// No description provided for @dashboardTodayMatch.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Match'**
  String get dashboardTodayMatch;

  /// No description provided for @dashboardMatchingTip.
  ///
  /// In en, this message translates to:
  /// **'Matching Tips'**
  String get dashboardMatchingTip;

  /// No description provided for @dashboardNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Wait for today\'s recommendation'**
  String get dashboardNoMatchTitle;

  /// No description provided for @dashboardNoMatchDesc.
  ///
  /// In en, this message translates to:
  /// **'New connections arrive daily at 12 PM'**
  String get dashboardNoMatchDesc;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorGeneric(String error);

  /// No description provided for @errorProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found. Please set up your profile again.'**
  String get errorProfileNotFound;

  /// No description provided for @errorChatCreate.
  ///
  /// In en, this message translates to:
  /// **'Error creating chat room.'**
  String get errorChatCreate;

  /// No description provided for @errorChatLoad.
  ///
  /// In en, this message translates to:
  /// **'Error loading chat: {error}'**
  String errorChatLoad(String error);

  /// No description provided for @errorLogout.
  ///
  /// In en, this message translates to:
  /// **'Error during logout'**
  String get errorLogout;

  /// No description provided for @errorImageSelect.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String errorImageSelect(String error);

  /// No description provided for @errorProfileCreate.
  ///
  /// In en, this message translates to:
  /// **'Error creating profile: {error}'**
  String errorProfileCreate(String error);

  /// No description provided for @successProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile successfully updated.'**
  String get successProfileUpdated;

  /// No description provided for @successProfileUpdatedReview.
  ///
  /// In en, this message translates to:
  /// **'Profile successfully updated. Awaiting admin review.'**
  String get successProfileUpdatedReview;

  /// No description provided for @successProfileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile successfully created. Awaiting admin approval.'**
  String get successProfileCreated;

  /// No description provided for @approvalWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval Pending'**
  String get approvalWaitingTitle;

  /// No description provided for @approvalWaitingMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile Under Review'**
  String get approvalWaitingMessage;

  /// No description provided for @approvalWaitingDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing all profiles for safe connections.\nYou\'ll receive a notification when approved!'**
  String get approvalWaitingDesc;

  /// No description provided for @approvalStillPending.
  ///
  /// In en, this message translates to:
  /// **'Still under review. Please wait a bit longer.'**
  String get approvalStillPending;

  /// No description provided for @approvalInfoVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Thorough Verification'**
  String get approvalInfoVerificationTitle;

  /// No description provided for @approvalInfoVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'We carefully review all profile photos and information'**
  String get approvalInfoVerificationDesc;

  /// No description provided for @approvalInfoProcessTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Processing'**
  String get approvalInfoProcessTitle;

  /// No description provided for @approvalInfoProcessDesc.
  ///
  /// In en, this message translates to:
  /// **'Reviews are usually completed within 24 hours'**
  String get approvalInfoProcessDesc;

  /// No description provided for @approvalInfoNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Notification'**
  String get approvalInfoNotificationTitle;

  /// No description provided for @approvalInfoNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified via app and email when approved'**
  String get approvalInfoNotificationDesc;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @checkApprovalStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Approval Status'**
  String get checkApprovalStatus;

  /// No description provided for @errorCheckingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error checking status: {error}'**
  String errorCheckingStatus(String error);

  /// No description provided for @approvalRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Approval Rejected'**
  String get approvalRejectedTitle;

  /// No description provided for @approvalRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile Approval Rejected'**
  String get approvalRejectedMessage;

  /// No description provided for @approvalRejectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Some profiles may not be approved for safe service operation.\nPlease refer to the guidelines below and edit your profile.'**
  String get approvalRejectedDesc;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @guidelinePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo Guidelines'**
  String get guidelinePhotoTitle;

  /// No description provided for @guidelinePhoto1.
  ///
  /// In en, this message translates to:
  /// **'Clear photo showing your face'**
  String get guidelinePhoto1;

  /// No description provided for @guidelinePhoto2.
  ///
  /// In en, this message translates to:
  /// **'Clear and appropriate quality photo'**
  String get guidelinePhoto2;

  /// No description provided for @guidelinePhoto3.
  ///
  /// In en, this message translates to:
  /// **'No inappropriate content'**
  String get guidelinePhoto3;

  /// No description provided for @guidelinePhoto4.
  ///
  /// In en, this message translates to:
  /// **'Your own photo, not someone else\'s'**
  String get guidelinePhoto4;

  /// No description provided for @guidelineInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Information Guidelines'**
  String get guidelineInfoTitle;

  /// No description provided for @guidelineInfo1.
  ///
  /// In en, this message translates to:
  /// **'Write only truthful information'**
  String get guidelineInfo1;

  /// No description provided for @guidelineInfo2.
  ///
  /// In en, this message translates to:
  /// **'No inappropriate language'**
  String get guidelineInfo2;

  /// No description provided for @guidelineInfo3.
  ///
  /// In en, this message translates to:
  /// **'Comply with privacy protection'**
  String get guidelineInfo3;

  /// No description provided for @guidelineInfo4.
  ///
  /// In en, this message translates to:
  /// **'Content that doesn\'t offend others'**
  String get guidelineInfo4;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @supportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Support feature coming soon.'**
  String get supportComingSoon;

  /// No description provided for @errorLoadingMatch.
  ///
  /// In en, this message translates to:
  /// **'Error loading match information'**
  String get errorLoadingMatch;

  /// No description provided for @noMatchToday.
  ///
  /// In en, this message translates to:
  /// **'No new matches today'**
  String get noMatchToday;

  /// No description provided for @noMatchTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll introduce someone new tomorrow!\nNew matches are revealed daily at 12 PM.'**
  String get noMatchTodayDesc;

  /// No description provided for @untilNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Until next match'**
  String get untilNextMatch;

  /// No description provided for @matchReady.
  ///
  /// In en, this message translates to:
  /// **'🎉 Today\'s match is ready!'**
  String get matchReady;

  /// No description provided for @revealAtNoon.
  ///
  /// In en, this message translates to:
  /// **'Revealed at 12 PM'**
  String get revealAtNoon;

  /// No description provided for @matchReadyShort.
  ///
  /// In en, this message translates to:
  /// **'Today\'s match is ready!'**
  String get matchReadyShort;

  /// No description provided for @matchPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} special connection(s) waiting for you.\nRevealed at 12 PM.'**
  String matchPendingDesc(int count);

  /// No description provided for @likeSent.
  ///
  /// In en, this message translates to:
  /// **'💖 Like sent!'**
  String get likeSent;

  /// No description provided for @passMessage.
  ///
  /// In en, this message translates to:
  /// **'See you next time'**
  String get passMessage;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorOccurred(String error);

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @noticeEarlyAdopterTitle.
  ///
  /// In en, this message translates to:
  /// **'🎁 Early Adopter Special Offer!'**
  String get noticeEarlyAdopterTitle;

  /// No description provided for @noticeEarlyAdopterDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoy unlimited chat for free until 2025! A special offer for early users.'**
  String get noticeEarlyAdopterDesc;

  /// No description provided for @noticeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! 🎉'**
  String get noticeWelcomeTitle;

  /// No description provided for @noticeWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet new connections daily at 12 PM. If you\'re both interested, you can start chatting!'**
  String get noticeWelcomeDesc;

  /// No description provided for @noticeServiceLaunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Official Launch! 🚀'**
  String get noticeServiceLaunchTitle;

  /// No description provided for @noticeServiceLaunchDesc.
  ///
  /// In en, this message translates to:
  /// **'Hearty has officially launched! We\'re continuously updating for better matching.'**
  String get noticeServiceLaunchDesc;

  /// No description provided for @noticeRealtimeChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time Chat Open! 💬'**
  String get noticeRealtimeChatTitle;

  /// No description provided for @noticeRealtimeChatDesc.
  ///
  /// In en, this message translates to:
  /// **'Real-time chat available when you both like each other. Start with your first message!'**
  String get noticeRealtimeChatDesc;

  /// No description provided for @waitForRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Wait for today\'s recommendation'**
  String get waitForRecommendation;

  /// No description provided for @newMatchAtNoon.
  ///
  /// In en, this message translates to:
  /// **'New connections arrive daily at 12 PM'**
  String get newMatchAtNoon;

  /// No description provided for @userAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age} years old'**
  String userAgeYears(String name, int age);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @mutualInterest.
  ///
  /// In en, this message translates to:
  /// **'Both interested! 💕'**
  String get mutualInterest;

  /// No description provided for @receivedInterest.
  ///
  /// In en, this message translates to:
  /// **'Interested in you 💕'**
  String get receivedInterest;

  /// No description provided for @sentInterest.
  ///
  /// In en, this message translates to:
  /// **'You expressed interest 💝'**
  String get sentInterest;

  /// No description provided for @newMatchWaiting.
  ///
  /// In en, this message translates to:
  /// **'A new connection awaits'**
  String get newMatchWaiting;

  /// No description provided for @matchingTips.
  ///
  /// In en, this message translates to:
  /// **'Matching Tips'**
  String get matchingTips;

  /// No description provided for @tipProfilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Attractive Profile Photo'**
  String get tipProfilePhotoTitle;

  /// No description provided for @tipProfilePhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload photos with a natural smile and good lighting'**
  String get tipProfilePhotoDesc;

  /// No description provided for @tipInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Interests'**
  String get tipInterestsTitle;

  /// No description provided for @tipInterestsDesc.
  ///
  /// In en, this message translates to:
  /// **'Updating hobbies and interests frequently helps you get better matches'**
  String get tipInterestsDesc;

  /// No description provided for @tipFirstMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'First Message Tips'**
  String get tipFirstMessageTitle;

  /// No description provided for @tipFirstMessageDesc.
  ///
  /// In en, this message translates to:
  /// **'Check their profile and start conversation with common interests'**
  String get tipFirstMessageDesc;

  /// No description provided for @chatPartner.
  ///
  /// In en, this message translates to:
  /// **'Chat Partner'**
  String get chatPartner;

  /// No description provided for @sendFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Send your first message! 💕'**
  String get sendFirstMessage;

  /// No description provided for @sendFirstMessageDesc.
  ///
  /// In en, this message translates to:
  /// **'You both liked each other - it\'s a special connection.\nStart the conversation naturally!'**
  String get sendFirstMessageDesc;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get enterMessage;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @weekdayFormat.
  ///
  /// In en, this message translates to:
  /// **'{weekday}'**
  String weekdayFormat(String weekday);

  /// No description provided for @monthDay.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String monthDay(int month, int day);

  /// No description provided for @yearMonthDay.
  ///
  /// In en, this message translates to:
  /// **'{year}/{month}/{day}'**
  String yearMonthDay(int year, int month, int day);

  /// No description provided for @yesterdayTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayTime(String time);

  /// No description provided for @weekdayTime.
  ///
  /// In en, this message translates to:
  /// **'{weekday} {time}'**
  String weekdayTime(String weekday, String time);

  /// No description provided for @monthDayTime.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day} {time}'**
  String monthDayTime(int month, int day, String time);

  /// No description provided for @yearMonthDayTime.
  ///
  /// In en, this message translates to:
  /// **'{year}/{month}/{day} {time}'**
  String yearMonthDayTime(int year, int month, int day, String time);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navRecommendations;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get settingsNotification;

  /// No description provided for @settingsNotificationMatch.
  ///
  /// In en, this message translates to:
  /// **'Match Notifications'**
  String get settingsNotificationMatch;

  /// No description provided for @settingsNotificationMatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for new matches'**
  String get settingsNotificationMatchDesc;

  /// No description provided for @settingsNotificationChat.
  ///
  /// In en, this message translates to:
  /// **'Chat Notifications'**
  String get settingsNotificationChat;

  /// No description provided for @settingsNotificationChatDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for new messages'**
  String get settingsNotificationChatDesc;

  /// No description provided for @settingsNotificationSystem.
  ///
  /// In en, this message translates to:
  /// **'System Notifications'**
  String get settingsNotificationSystem;

  /// No description provided for @settingsNotificationSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive app updates and announcements'**
  String get settingsNotificationSystemDesc;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get settingsLanguageDesc;

  /// No description provided for @settingsAppInfo.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get settingsAppInfo;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get settingsContact;

  /// No description provided for @settingsContactDesc.
  ///
  /// In en, this message translates to:
  /// **'edgein00@gmail.com'**
  String get settingsContactDesc;

  /// No description provided for @settingsReview.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get settingsReview;

  /// No description provided for @settingsReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Rate Hearty on the App Store'**
  String get settingsReviewDesc;

  /// No description provided for @settingsContactSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Please contact us via email: edgein00@gmail.com'**
  String get settingsContactSnackbar;

  /// No description provided for @settingsReviewSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Opening App Store'**
  String get settingsReviewSnackbar;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어 (Korean)'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'One special connection a day'**
  String get splashTagline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
