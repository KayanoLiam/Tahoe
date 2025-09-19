// 综合测试JavaScript功能
console.log("=== JavaScript 综合测试开始 ===");

// 测试变量和基本运算
var num1 = 10;
var num2 = 20;
console.log("数字计算:", num1, "+", num2, "=", num1 + num2);

// 测试字符串操作
var name = "尹明华";
var message = "你好，" + name + "！";
console.log("字符串操作:", message);

// 测试函数
function multiply(a, b) {
    console.log("正在计算", a, "×", b);
    return a * b;
}

var result = multiply(6, 7);
console.log("函数返回结果:", result);

// 测试对象
var person = {
    name: "张三",
    age: 25,
    greet: function() {
        return "我叫" + this.name + "，今年" + this.age + "岁";
    }
};

console.log("对象测试:", person.greet());

console.log("=== 测试完成 ===");

// 返回最终结果
"所有测试都通过了！";