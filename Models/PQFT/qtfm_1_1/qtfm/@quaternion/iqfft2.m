function Y = iqfft2(X, A, L)
% IQFFT2 Inverse Discrete quaternion Fourier transform.
%
% This function calculates the inverse fast quaternion 2D Fourier transform
% of (columns of) X. A specifies the transform axis (that is the direction
% in 3-space of the vector part of the hypercomplex exponential). It must
% be a pure quaternion (real or complex) but it need not have unit modulus.
% L specifies whether the quaternion exponential is on the left ('L') or
% right ('R').
%
% See also: QFFT2, FFT2, IFFT2.

% Copyright � 2005 Stephen J. Sangwine and Nicolas Le Bihan.
% See the file : Copyright.m for further details.

% Reference:
%
% Salem Said, Nicolas Le Bihan and Stephen J. Sangwine,
% Fast complexified quaternion Fourier transform,
% arXiv:math.NA/0603578, 24 March 2006. Available at http://www.arxiv.org/.

error(nargchk(3, 3, nargin)), error(nargoutchk(0, 1, nargout))

if ~isscalar(A)
    error('The transform axis cannot be a matrix or vector.');
end

if ~isa(A, 'quaternion') || ~ispure(A)
    error('The transform axis must be a pure quaternion.')
end

if L ~= 'L' && L ~= 'R'
    error('L must have the value ''L'' or ''R''.');
end

S = 1;
if L == 'R'
    S = -1;  % S is a sign bit used (in effect) to conjugate one of the complex
             % components below when the exponential is on the right.  In fact,
             % instead of conjugating the exponential (which would require an
             % inverse fft (ifft), we conjugate the complex component before and 
             % after the transformation. This achieves the same effect because
             % the inverse transform may always be computed by taking the
             % conjugate before and after the transformation (this is a
             % standard DFT trick).
end

A = unit(A); % Ensure that A is a unit (pure) quaternion.
B = orthonormal_basis(A);

% Compute the transform. This is done by changing the basis of all the
% elements of the matrix or vector X to the transform axis (which may be
% real or complex). The quaternion elements can then be regrouped as
% complex values and their FFTs computed with the standard Matlab function.
% We then have to regroup the complex results into quaternion form and
% invert the change of basis.

% Note that we compute here a real quaternion FFT (two complex FFTs) if
% both X and the axis are real, otherwise we compute a complex quaternion
% FFT (four complex FFTs). The decision is made after the change of basis,
% because by this point, if X is still real, a real quaternion FFT is
% needed. It is theoretically possible to use the complex code for both
% cases, but in the real case this would result in two unnecessary FFTs
% being computed, which is a heavy cost.

X = change_basis(X, B);

if isreal(X)

    % Compute the two complex FFTs using the standard Matlab complex FFT
    % function.

    C1 = ifft2(complex(scalar(X),      x(X)));
    C2 = ifft2(complex(     y(X), S .* z(X)));

    % Compose a real quaternion result from the two complex results.

    Y = quaternion(real(C1), imag(C1), real(C2), S .* imag(C2));
else

    % Compute the four complex FFTs using the standard Matlab complex FFT
    % function.

    C1 = ifft2(complex(real(scalar(X)),      real(x(X))));
    C2 = ifft2(complex(imag(scalar(X)),      imag(x(X))));
    C3 = ifft2(complex(real(     y(X)), S .* real(z(X))));
    C4 = ifft2(complex(imag(     y(X)), S .* imag(z(X))));

    % Notice here that conjugation of the C3 and C4 components
    % (multiplication by S) is implemented by negating the complex number
    % formed from their imaginary parts.

    Y = quaternion(complex(real(C1), real(C2)), ...
                   complex(imag(C1), imag(C2)), ...
                   complex(real(C3), real(C4)), ...
              S .* complex(imag(C3), imag(C4)));
end

Y = change_basis(Y, B.'); % Change back to the original basis.