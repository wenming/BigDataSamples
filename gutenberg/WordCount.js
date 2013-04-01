var map = function (key, value, context) {
    var words = value.split(/[^a-zA-Z]/);
    for (var i = 0; i < words.length; i++) {
        if (words[i] !== "") {
            context.write(words[i].toLowerCase(), 1);
        }
    }
};var reduce = function (key, values, context) {
    var sum = 0;
    while (values.hasNext()) {
        sum += parseInt(values.next());
    }
    context.write(key, sum);
};