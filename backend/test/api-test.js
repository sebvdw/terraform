const request = require("supertest")("http://localhost:5000");
const expect = require("chai").expect;

// MAKE SURE THAT THE ENVIRONMENT VARIABLE FOR THE SERVER IS SET TO testing AND THAT THE SERVER IS STARTED FIRST.
// THE SERVER HAS TO BE RESTARTED EVERYTIME YOU WANT TO RUN THIS TEST!!!

describe("GET /", function() {
  it("returns all people in the database", async function() {
    const response = await request.get("/");
    expect(response.status).to.equal(200);
    expect(response.body.length).to.equal(2);
    expect(response.body[0]["fullname"]).to.equal("Jan Jansen");
  });
});

describe("GET /search", function() {
  it("should find user Jan Jansen", async function() {
    const response = await request.get("/search?shortname=jja");
    expect(response.status).to.equal(200);
    expect(response.body.length).to.equal(1);
    expect(response.body[0]["fullname"]).to.equal("Jan Jansen");
  });
  it("should find user Peter Peters", async function() {
    const response = await request.get("/search?shortname=ppe01");
    expect(response.body.length).to.equal(1);
    expect(response.body[0]["fullname"]).to.equal("Peter Peters");
  });
  it("should find both users", async function() {
    const response = await request.get("/search?shortname=01");
    expect(response.status).to.eql(200);
    expect(response.body.length).to.equal(2);
  });
  it("should not find any user with shortname tst01", async function() {
    const response = await request.get("/search?shortname=tst01");
    expect(response.status).to.eql(200);
    expect(response.body.length).to.equal(0);
  });
});

describe("POST /", function() {
  it("should be able to add new user", async function() {
    let response = await request
        .post("/")
        .send({fullname: "Klaas Klaasen", shortname: "kkl01", email: "k.klaasen@test.saxion.nl"});

    // Now check if the record is present
    response = await request.get("/search?shortname=kkl01");
    expect(response.status).to.eql(200);
    expect(response.body.length).to.equal(1);
    expect(response.body[0]["fullname"]).to.equal("Klaas Klaasen");
    expect(response.body[0]["email"]).to.equal("k.klaasen@test.saxion.nl");
  });

  // TODO for students: write a couple of bad weather tests, to make sure no duplicate users can be added and also no missing attributes are allowed!
});
