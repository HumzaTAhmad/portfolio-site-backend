// In a Cypress test file, like cypress/integration/test_lambda_function_spec.js

describe('Lambda Function Test', () => {
  it('increments the visit counter', () => {
    const url = 'https://5ykalw7bz6.execute-api.us-east-1.amazonaws.com/v1';

    // First PUT request
    cy.request('PUT', url).then((response1) => {
      expect(response1.status).to.eq(200);
      const visits1 = response1.body.visits;

      // Second PUT request
      cy.request('PUT', url).then((response2) => {
        expect(response2.status).to.eq(200);
        const visits2 = response2.body.visits;

        // Assert that visits have incremented
        expect(visits2).to.be.greaterThan(visits1);
      });
    });
  });
});
/*
// Second group of tests
describe('Website Visits Test', () => {
  it('check visit counter', () => {
    const url = Cypress.env(process.env.API_GATEWAY_URL);;
    cy.request('PUT', url).then((response1) => {
      expect(response1.status).to.eq(200);
      const visits = response1.body.visits;
      
      cy.visit('https://www.humza-resume.com/')
      cy.get('#visitCount')
  // Wait for the text of #visitCount to be a number
      .should(($el) => {
        const text = $el.text();
        expect(text).to.match(/^\d+$/, 'Expected #visitCount to be a number');
      })
      .then(($el) => {
        // Now that we've ensured the text is a number, parse it
        const currentCount = parseInt($el.text(), 10);
        // Perform the assertion to compare the current count with visits + 1
        expect(currentCount).to.eq(visits + 1);
      });
    });
  });
});
*/