$("#krane-call-attack").click(function () {
  $.post("https://qb-phone/HireHitman", JSON.stringify({}), function (data) {});
  QB.Phone.Functions.Close();
});
