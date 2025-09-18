import { expect, test } from "bun:test";

import { getProperty } from "./objutil.js";

test("getProperty", () => {
	const o1 = { a: 1, b: 10 };
	const l = [8, 3];
	expect(getProperty("a", o1)).toBe(1);
	expect(getProperty("b", o1)).toBe(10);
	expect(getProperty(0, l)).toBe(8);
	expect(getProperty(1, l)).toBe(3);

	expect(() => getProperty("other", o1)).toThrowError();
	expect(() => getProperty(1, o1)).toThrowError();
	expect(() => getProperty(2, l)).toThrowError();
});
