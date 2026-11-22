import 'content/en_content.dart';
import 'content/es_couple_content.dart';
import 'content/es_family_content.dart';
import 'content/es_friends_content.dart';
import 'content/es_party_content.dart';
import 'game_models.dart';
import 'imported_adult_content.dart';

const cardsPerType = 100;

List<GameCard> buildDeck(
  GameMode mode,
  Intensity intensity, {
  bool english = false,
}) => [
  ...contentFor(
    mode,
    intensity,
    CardType.verdad,
    english: english,
  ).map((text) => GameCard(CardType.verdad, text)),
  ...contentFor(
    mode,
    intensity,
    CardType.reto,
    english: english,
  ).map((text) => GameCard(CardType.reto, text)),
]..shuffle();

List<String> contentFor(
  GameMode mode,
  Intensity intensity,
  CardType type, {
  bool english = false,
}) {
  if (english) return _englishContentFor(mode, type);
  if (mode == GameMode.familia) {
    return _takeUnique(
      type == CardType.verdad ? esFamilyTruths : esFamilyDares,
    );
  }
  final imported =
      importedAdultContent[_categoryKey(
        mode,
        intensity,
      )]?[type == CardType.verdad ? 'verdad' : 'reto'] ??
      const <String>[];
  final curated = _spanishCuratedFor(mode, intensity, type);
  return _takeUnique([...imported, ...curated]);
}

List<String> _takeUnique(Iterable<String> items) =>
    <String>{...items}.take(cardsPerType).toList();

List<String> _spanishCuratedFor(
  GameMode mode,
  Intensity intensity,
  CardType type,
) {
  final isTruth = type == CardType.verdad;
  return switch ((mode, intensity)) {
    (GameMode.amigos, Intensity.suave) =>
      isTruth ? esFriendsSuaveTruths : esFriendsSuaveDares,
    (GameMode.amigos, Intensity.atrevido) =>
      isTruth ? esFriendsAtrevidoTruths : esFriendsAtrevidoDares,
    (GameMode.amigos, Intensity.extremo) =>
      isTruth ? esFriendsExtremoTruths : esFriendsExtremoDares,
    (GameMode.pareja, Intensity.suave) =>
      isTruth ? esCoupleSuaveTruths : esCoupleSuaveDares,
    (GameMode.pareja, Intensity.atrevido) =>
      isTruth ? esCoupleAtrevidoExtraTruths : esCoupleAtrevidoExtraDares,
    (GameMode.pareja, Intensity.extremo) =>
      isTruth ? esCoupleExtremoExtraTruths : esCoupleExtremoExtraDares,
    (GameMode.fiesta, Intensity.suave) =>
      isTruth ? esPartySuaveTruths : esPartySuaveDares,
    (GameMode.fiesta, Intensity.atrevido) =>
      isTruth ? esPartyAtrevidoExtraTruths : esPartyAtrevidoExtraDares,
    (GameMode.fiesta, Intensity.extremo) =>
      isTruth ? esPartyExtremoExtraTruths : esPartyExtremoExtraDares,
    (GameMode.familia, _) => isTruth ? esFamilyTruths : esFamilyDares,
  };
}

List<String> _englishContentFor(GameMode mode, CardType type) {
  final isTruth = type == CardType.verdad;
  return _takeUnique(switch (mode) {
    GameMode.familia => isTruth ? enFamilyTruths : enFamilyDares,
    GameMode.amigos => isTruth ? enFriendsTruths : enFriendsDares,
    GameMode.pareja => isTruth ? enCoupleTruths : enCoupleDares,
    GameMode.fiesta => isTruth ? enPartyTruths : enPartyDares,
  });
}

String _categoryKey(GameMode mode, Intensity intensity) =>
    '${mode.name}_${intensity.name}';
