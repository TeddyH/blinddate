import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Profile setup options using i18n for internationalization
class ProfileOptions {
  // Personality/charm tags (max 5 selections)
  static List<String> personalityTraits(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.personalityHumorous,
      l10n.personalitySerious,
      l10n.personalityEnergetic,
      l10n.personalityCalm,
      l10n.personalityConsiderate,
      l10n.personalityHonest,
      l10n.personalityPositive,
      l10n.personalityThoughtful,
      l10n.personalityPassionate,
      l10n.personalityRelaxed,
      l10n.personalityIntellectual,
      l10n.personalityEmotional,
      l10n.personalityRealistic,
      l10n.personalityCreative,
      l10n.personalityOrganized,
      l10n.personalitySpontaneous,
    ];
  }

  // What others say about me (max 3 selections)
  static List<String> othersSayAboutMe(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.othersFunny,
      l10n.othersKind,
      l10n.othersCool,
      l10n.othersPretty,
      l10n.othersSmart,
      l10n.othersSensible,
      l10n.othersGentle,
      l10n.othersChill,
      l10n.othersCute,
      l10n.othersReliable,
      l10n.othersComfortable,
      l10n.othersCharming,
      l10n.othersTrustworthy,
      l10n.othersLeadership,
    ];
  }

  // Ideal type/desired style (max 5 selections)
  static List<String> idealTypeTraits(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.idealHumor,
      l10n.idealSeriousness,
      l10n.idealEnergy,
      l10n.idealCalmness,
      l10n.idealConversation,
      l10n.idealConsideration,
      l10n.idealPassion,
      l10n.idealRelaxation,
      l10n.idealHonesty,
      l10n.idealPositivity,
      l10n.idealIntellect,
      l10n.idealEmotion,
      l10n.idealPlanning,
      l10n.idealSpontaneity,
      l10n.idealLeadership,
      l10n.idealEmpathy,
    ];
  }

  // Date styles (max 2 selections)
  static List<String> dateStyles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.dateActiveActivities,
      l10n.dateRelaxedWalk,
      l10n.dateFoodTour,
      l10n.dateCafe,
      l10n.dateCulture,
      l10n.dateHomeRelax,
      l10n.dateDrive,
      l10n.dateExercise,
      l10n.dateMovieShow,
      l10n.dateShopping,
      l10n.dateHealing,
      l10n.dateNewExperience,
    ];
  }

  // Drinking style (single selection)
  static Map<String, String> drinkingStyles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return {
      'none': l10n.drinkingNone,
      'sometimes': l10n.drinkingSometimes,
      'often': l10n.drinkingOften,
      'social': l10n.drinkingSocial,
    };
  }

  // Smoking status (single selection)
  static Map<String, String> smokingStatuses(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return {
      'non_smoker': l10n.smokingNonSmoker,
      'smoker': l10n.smokingSmoker,
    };
  }

  // Job categories (optional)
  static List<String> jobCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.jobUnemployed,
      l10n.jobIT,
      l10n.jobFinance,
      l10n.jobMedical,
      l10n.jobEducation,
      l10n.jobDesign,
      l10n.jobMedia,
      l10n.jobService,
      l10n.jobManufacturing,
      l10n.jobConstruction,
      l10n.jobRetail,
      l10n.jobPublic,
      l10n.jobLegal,
      l10n.jobResearch,
      l10n.jobFreelance,
      l10n.jobBusiness,
      l10n.jobStudent,
      l10n.jobOther,
    ];
  }

  // Interests (1-5 selections)
  static List<String> interests(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.interestMovies,
      l10n.interestMusic,
      l10n.interestReading,
      l10n.interestTravel,
      l10n.interestExercise,
      l10n.interestCooking,
      l10n.interestPhotography,
      l10n.interestGaming,
      l10n.interestCafe,
      l10n.interestFood,
      l10n.interestShopping,
      l10n.interestExhibitions,
      l10n.interestConcerts,
      l10n.interestSports,
      l10n.interestHiking,
      l10n.interestBeach,
      l10n.interestPets,
      l10n.interestAlcohol,
      l10n.interestCoffee,
      l10n.interestDesserts,
      l10n.interestFashion,
      l10n.interestBeauty,
      l10n.interestCars,
      l10n.interestMotorcycles,
      l10n.interestDancing,
      l10n.interestKaraoke,
      l10n.interestInstruments,
      l10n.interestDrawing,
      l10n.interestCrafts,
      l10n.interestBaking,
      l10n.interestWine,
      l10n.interestBeer,
      l10n.interestCocktails,
      l10n.interestHomeWorkout,
      l10n.interestYogaPilates,
      l10n.interestSwimming,
      l10n.interestClimbing,
      l10n.interestGolf,
      l10n.interestTennis,
      l10n.interestBadminton,
      l10n.interestSoccer,
      l10n.interestBasketball,
      l10n.interestBaseball,
      l10n.interestRunning,
      l10n.interestCycling,
      l10n.interestCamping,
      l10n.interestFishing,
      l10n.interestSurfing,
      l10n.interestSkiSnowboard,
      l10n.interestDiving,
      l10n.interestDriving,
    ];
  }

  // MBTI types (no translation needed)
  static const List<String> mbtiTypes = [
    'ISTJ',
    'ISFJ',
    'INFJ',
    'INTJ',
    'ISTP',
    'ISFP',
    'INFP',
    'INTP',
    'ESTP',
    'ESFP',
    'ENFP',
    'ENTP',
    'ESTJ',
    'ESFJ',
    'ENFJ',
    'ENTJ',
  ];

  // Locations
  static List<String> locations(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.locationSeoul,
      l10n.locationIncheon,
      l10n.locationGyeonggiSouth,
      l10n.locationGyeonggiNorth,
      l10n.locationGangwon,
      l10n.locationChungbuk,
      l10n.locationChungnam,
      l10n.locationGyeongbuk,
      l10n.locationGyeongnam,
      l10n.locationJeonbuk,
      l10n.locationJeonnam,
      l10n.locationJeju,
    ];
  }

  // Gender
  static Map<String, String> genders(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return {
      'male': l10n.genderMale,
      'female': l10n.genderFemale,
    };
  }
}
